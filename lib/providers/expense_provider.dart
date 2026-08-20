import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';
import '../models/expense_model.dart';
import '../models/topic_filter.dart';
import '../repositories/expense_repository.dart';
import '../storage/topic_filter_storage.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository?>((ref) {
  final entryRepo = ref.watch(entryRepositoryProvider);
  if (entryRepo == null) return null;
  return ExpenseRepository(entryRepository: entryRepo);
});

class ExpenseState {
  final DateTime focusedMonth;
  final int year;
  final int month;
  final int day;
  final List<ExpenseModel> monthlyExpenses;
  final List<ExpenseModel> selectedDateExpenses;
  final Map<DateTime, Map<String, int>> monthlySummary;
  final ExpenseType? activeFilter;
  final TopicFilter topicFilter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const ExpenseState({
    required this.focusedMonth,
    required this.year,
    required this.month,
    required this.day,
    required this.monthlyExpenses,
    required this.selectedDateExpenses,
    required this.monthlySummary,
    this.activeFilter,
    this.topicFilter = const TopicFilterAll(),
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  factory ExpenseState.initial() {
    final now = DateTime.now();
    return ExpenseState(
      focusedMonth: DateTime(now.year, now.month),
      year: now.year,
      month: now.month,
      day: now.day,
      monthlyExpenses: const [],
      selectedDateExpenses: const [],
      monthlySummary: const {},
      isLoading: true,
    );
  }

  int get monthlyIncomeTotal => monthlyExpenses
      .where((e) => e.isIncome)
      .fold(0, (sum, e) => sum + e.amount);

  int get monthlyExpenseTotal => monthlyExpenses
      .where((e) => e.isExpense)
      .fold(0, (sum, e) => sum + e.amount);

  List<ExpenseModel> get filteredSelectedDateExpenses {
    var list = selectedDateExpenses;
    if (activeFilter != null) {
      list = list.where((e) => e.type == activeFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((e) => e.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  ExpenseState copyWith({
    DateTime? focusedMonth,
    DateTime? selectedDate,
    List<ExpenseModel>? monthlyExpenses,
    List<ExpenseModel>? selectedDateExpenses,
    Map<DateTime, Map<String, int>>? monthlySummary,
    ExpenseType? Function()? activeFilter,
    TopicFilter? topicFilter,
    String? searchQuery,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ExpenseState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      year: selectedDate?.year ?? this.year,
      month: selectedDate?.month ?? this.month,
      day: selectedDate?.day ?? this.day,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      selectedDateExpenses: selectedDateExpenses ?? this.selectedDateExpenses,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
      topicFilter: topicFilter ?? this.topicFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

/// Manages expense data for the main Expense screen.
///
/// [expenseNotifierProvider] watches [expenseRepositoryProvider], which in
/// turn depends on [entryRepositoryProvider] → [bootstrapNotifierProvider].
/// When bootstrap succeeds the repository chain resolves from null to a real
/// instance, causing Riverpod to recreate this notifier with a non-null
/// repository. The constructor then kicks off the initial load automatically —
/// no manual trigger from the UI is needed.
///
/// After that, tapping the Expenses tab calls [load] explicitly to refresh.
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepository? _repository;
  final TopicFilterStorage _topicFilterStorage;

  ExpenseNotifier(this._repository, this._topicFilterStorage)
      : super(
          ExpenseState.initial().copyWith(
            topicFilter: _topicFilterStorage.getFilter(),
          ),
        ) {
    if (_repository != null) load();
  }

  Future<void> load() => _load(state.focusedMonth);

  Future<void> _load(DateTime month) async {
    final repo = _repository;
    if (repo == null) return;
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final m = DateTime(month.year, month.month);
      final today = DateTime.now();
      final selectedDate = DateTime(today.year, today.month, today.day);
      final topicIds = state.topicFilter.queryTopicIds;
      final monthly =
          await repo.getExpensesByMonth(m.year, m.month, topicIds: topicIds);
      final summary = repo.buildMonthlySummary(monthly);
      final daily = await repo.getExpensesByDate(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        topicIds: topicIds,
      );
      state = state.copyWith(
        focusedMonth: m,
        selectedDate: selectedDate,
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  Future<void> changeMonth(DateTime month) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final m = DateTime(month.year, month.month);
      // 현재 선택된 날짜와 같은 일(day)로 이동한다. 그 달에 없는 날짜라면
      // (예: 1/31 → 2월) 그 달의 마지막 날로 대체한다.
      final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
      final targetDay = state.day > daysInMonth ? daysInMonth : state.day;
      final selectedDate = DateTime(m.year, m.month, targetDay);
      final topicIds = state.topicFilter.queryTopicIds;
      final monthly =
          await repo.getExpensesByMonth(m.year, m.month, topicIds: topicIds);
      final summary = repo.buildMonthlySummary(monthly);
      final daily = await repo.getExpensesByDate(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        topicIds: topicIds,
      );
      state = state.copyWith(
        focusedMonth: m,
        selectedDate: selectedDate,
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  /// 특정 날짜로 곧장 이동한다 (달/일을 모두 그 날짜에 맞춘다). 알림 탭으로 특정
  /// entry의 날짜로 이동할 때처럼, 현재 선택된 일(day)을 유지하는 [changeMonth]와
  /// 달리 목표 날짜를 그대로 사용한다.
  Future<void> goToDate(int year, int month, int day) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final m = DateTime(year, month);
      final topicIds = state.topicFilter.queryTopicIds;
      final monthly =
          await repo.getExpensesByMonth(m.year, m.month, topicIds: topicIds);
      final summary = repo.buildMonthlySummary(monthly);
      final daily = await repo.getExpensesByDate(
        year,
        month,
        day,
        topicIds: topicIds,
      );
      state = state.copyWith(
        focusedMonth: m,
        selectedDate: DateTime(year, month, day),
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  /// 화면에 보인 entry들을 읽음 처리한다 (스크롤 기반, 디바운스되어 호출됨).
  /// 실패해도 조용히 무시 — 다음에 다시 보이면 재시도된다.
  Future<void> markEntriesRead(Iterable<int> entryIds) async {
    final repo = _repository;
    final ids = entryIds.toSet();
    if (repo == null || ids.isEmpty) return;
    try {
      await repo.markEntriesRead(ids.toList());
      state = state.copyWith(
        monthlyExpenses: _markRead(state.monthlyExpenses, ids),
        selectedDateExpenses: _markRead(state.selectedDateExpenses, ids),
      );
    } catch (_) {
      // 네트워크 오류 — 다음에 다시 보이면 재시도됨
    }
  }

  List<ExpenseModel> _markRead(List<ExpenseModel> expenses, Set<int> ids) {
    return expenses
        .map((e) => (e.id != null && ids.contains(e.id)) ? e.copyWith(read: true) : e)
        .toList();
  }

  Future<void> selectDate(int year, int month, int day) async {
    final date = DateTime(year, month, day); // local
    final repo = _repository;
    if (repo == null) return;
    try {
      final daily = await repo.getExpensesByDate(
        year,
        month,
        day,
        topicIds: state.topicFilter.queryTopicIds,
      );
      state = state.copyWith(
        selectedDate: date,
        selectedDateExpenses: daily,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.addExpense(expense);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.updateExpense(expense);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  Future<void> deleteExpense(int id) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.deleteExpense(id);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }

  void searchExpenses(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void filterExpenses(ExpenseType? type) {
    state = state.copyWith(activeFilter: () => type);
  }

  /// 조회할 토픽 범위를 바꾼다. 선택 상태는 로컬에 저장되어 다음 실행에도 유지된다.
  Future<void> filterByTopics(TopicFilter filter) async {
    state = state.copyWith(topicFilter: filter);
    await _topicFilterStorage.saveFilter(filter);
    await refresh();
  }

  /// 새로 구독한 토픽을 현재 필터에 포함시킨다. 전체 선택(all) 상태라면
  /// 이미 모든 토픽이 보이는 중이므로 그대로 둔다.
  Future<void> includeTopicInSelection(int topicId) async {
    final current = state.topicFilter;
    if (current.isSelected(topicId)) return;
    await filterByTopics(current.includingTopic(topicId));
  }

  /// 현재 월/선택된 날짜의 데이터를 다시 불러온다. 전체 화면 로딩 스피너를 띄우지 않으므로
  /// pull-to-refresh처럼 기존 화면을 유지한 채 갱신하는 용도로도 쓸 수 있다.
  Future<void> refresh() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final topicIds = state.topicFilter.queryTopicIds;
      final monthly = await repo.getExpensesByMonth(
        state.focusedMonth.year,
        state.focusedMonth.month,
        topicIds: topicIds,
      );
      final summary = repo.buildMonthlySummary(monthly);
      final daily = await repo.getExpensesByDate(
        state.year,
        state.month,
        state.day,
        topicIds: topicIds,
      );
      state = state.copyWith(
        monthlyExpenses: monthly,
        selectedDateExpenses: daily,
        monthlySummary: summary,
        error: () => null,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    }
  }
}

final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, ExpenseState>(
  (ref) => ExpenseNotifier(
    ref.watch(expenseRepositoryProvider),
    ref.watch(topicFilterStorageProvider),
  ),
);

/// 알림을 탭해서 특정 entry로 이동했을 때, 리스트에서 그 entry로 스크롤하고
/// 애니메이션을 재생하도록 신호를 보내는 데 쓴다. 애니메이션이 끝나면 null로 되돌아간다.
final highlightedEntryIdProvider = StateProvider<int?>((ref) => null);
