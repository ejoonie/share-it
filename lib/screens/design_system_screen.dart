import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// A live catalog using the same widgets as the product, with local demo state.
class DesignSystemScreen extends StatefulWidget {
  const DesignSystemScreen({super.key});

  @override
  State<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends State<DesignSystemScreen> {
  int _selectedDay = 3;
  int _selectedTab = 0;
  bool _showError = false;

  void _previewAction() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview only — no data saved.')),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Design system')),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: PiggySize.contentMaxWidth),
            child: ListView(
              key: const PageStorageKey('design-system-catalog'),
              padding: const EdgeInsets.all(PiggySpace.page),
              children: [
                Text(
                  'Sharable Piggy · v1',
                  style: PiggyType.label.copyWith(color: PiggyColors.accent),
                ),
                const SizedBox(height: PiggySpace.sm),
                const Text('Warm & cheerful', style: PiggyType.pageTitle),
                const SizedBox(height: PiggySpace.sm),
                const Text(
                  '크림색 바탕, 또렷한 블루퍼플, 명랑한 블루와 코랄. 색은 의미를 구분하고 글자는 정보를 선명하게 전달합니다.',
                  style: PiggyType.body,
                ),
                _section('01 · Color', '포인트는 선택과 행동에, 블루·코랄은 수입과 지출에 사용합니다.'),
                const Wrap(
                  spacing: PiggySpace.sm,
                  runSpacing: PiggySpace.sm,
                  children: [
                    _Swatch('Canvas', PiggyColors.background),
                    _Swatch('Surface', PiggyColors.surface),
                    _Swatch('Card', PiggyColors.card),
                    _Swatch('Ink', PiggyColors.ink),
                    _Swatch('Secondary', PiggyColors.secondary),
                    _Swatch('Brand', PiggyColors.accent),
                    _Swatch('Brand soft', PiggyColors.accentSoft),
                    _Swatch('Income', PiggyColors.income),
                    _Swatch('Income soft', PiggyColors.incomeSoft),
                    _Swatch('Expense', PiggyColors.expense),
                    _Swatch(
                      'Expense soft',
                      PiggyColors.expenseSoft,
                    ),
                  ],
                ),
                _section(
                  '02 · Typography',
                  '기본 시스템 글꼴을 사용합니다. 작은 설명보다 제목과 금액에 무게를 줍니다.',
                ),
                const PiggySurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('November 2026', style: PiggyType.pageTitle),
                      SizedBox(height: PiggySpace.md),
                      Text('Today · Nov 4', style: PiggyType.sectionTitle),
                      SizedBox(height: PiggySpace.md),
                      Text('Lunch with friends', style: PiggyType.itemTitle),
                      SizedBox(height: PiggySpace.sm),
                      Text('Food · My First Piggy', style: PiggyType.metadata),
                      SizedBox(height: PiggySpace.md),
                      Text(
                        '20 / 17 / 14 / 12 / 11 pt',
                        style: PiggyType.caption,
                      ),
                    ],
                  ),
                ),
                _section(
                  '03 · Daily summary',
                  '선택 날짜와 그날의 수입·지출을 한 카드에서 보여줍니다.',
                ),
                const PiggyDailySummaryCard(
                  eyebrow: 'Today',
                  date: 'Nov 5',
                  metadata: 'Thursday · 2026',
                  income: '\$2,800.00',
                  expenses: '\$144.01',
                ),
                _section(
                  '04 · Actions',
                  '한 영역에 강한 행동은 하나. 터치 영역은 최소 44 pt입니다.',
                ),
                Wrap(
                  spacing: PiggySpace.sm,
                  runSpacing: PiggySpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: _previewAction,
                      child: const Text('Save'),
                    ),
                    OutlinedButton(
                      onPressed: _previewAction,
                      child: const Text('Cancel'),
                    ),
                    const FilledButton(
                      onPressed: null,
                      child: Text('Disabled'),
                    ),
                    PiggyAddButton(onPressed: _previewAction),
                    const PiggyAddButton(onPressed: null),
                    TextButton(
                      onPressed: _previewAction,
                      style: TextButton.styleFrom(
                        foregroundColor: PiggyColors.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
                _section(
                  '05 · Inputs & states',
                  '입력칸을 눌러 포커스 상태를 확인하고, 오류 표시를 전환해보세요.',
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show validation error'),
                  value: _showError,
                  onChanged: (value) => setState(() => _showError = value),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'What was it for?',
                    errorText: _showError ? 'Add a title to continue.' : null,
                  ),
                ),
                const SizedBox(height: PiggySpace.md),
                const TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    hintText: 'USD',
                  ),
                ),
                _section(
                  '06 · Calendar states',
                  '오늘은 테두리, 선택은 채움. 오늘을 선택하면 채움이 우선합니다. 날짜를 눌러보세요.',
                ),
                PiggySurface(
                  child: Wrap(
                    spacing: PiggySpace.sm,
                    runSpacing: PiggySpace.md,
                    children: [
                      for (final day in [2, 3, 4, 5])
                        Column(
                          children: [
                            Semantics(
                              label:
                                  'November $day${day == 4 ? ', Today' : ''}',
                              selected: day == _selectedDay,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(PiggySize.tapTarget),
                                onTap: () => setState(() => _selectedDay = day),
                                child: SizedBox(
                                  width: PiggySize.tapTarget,
                                  height: PiggySize.tapTarget,
                                  child: Center(
                                    child: PiggyDayMarker(
                                      day: day,
                                      selected: day == _selectedDay,
                                      today: day == 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              day == 3
                                  ? '−\$22'
                                  : day == 4
                                      ? 'Today'
                                      : ' ',
                              style: PiggyType.metadata.copyWith(
                                color: day == 3
                                    ? PiggyColors.expense
                                    : PiggyColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(
                        width: PiggySize.tapTarget,
                        height: PiggySize.tapTarget,
                        child: Center(
                          child: PiggyDayMarker(day: 1, outside: true),
                        ),
                      ),
                    ],
                  ),
                ),
                _section(
                  '07 · Transactions',
                  '큰 개별 카드 대신 같은 날짜의 내역을 묶습니다. 색과 +/− 기호를 함께 씁니다.',
                ),
                PiggyTransactionRow(
                  title: 'Lunch with friends',
                  subtitle: 'Food · My First Piggy',
                  amount: '−\$12.00',
                  icon: Icons.restaurant_rounded,
                  tone: PiggyTone.expense,
                  last: false,
                  onTap: _previewAction,
                ),
                PiggyTransactionRow(
                  title: 'Monthly salary',
                  subtitle: 'Income · My First Piggy',
                  amount: '+\$2,800.00',
                  icon: Icons.south_west_rounded,
                  tone: PiggyTone.income,
                  first: false,
                  onTap: _previewAction,
                ),
                _section('08 · Navigation', '선택 탭에만 포인트 색과 연한 배경을 사용합니다.'),
                PiggyNavigationBar(
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      label: 'Expenses',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline_rounded),
                      label: 'Share',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Settings',
                    ),
                  ],
                ),
                _section(
                  '09 · Feedback',
                  '지출 코랄과 오류 의미를 분리합니다. 피드백에는 아이콘과 설명을 함께 표시합니다.',
                ),
                const _Feedback(
                  'Saved successfully',
                  Icons.check_circle_outline,
                  PiggyColors.success,
                  PiggyColors.successSoft,
                ),
                const SizedBox(height: PiggySpace.sm),
                const _Feedback(
                  'Check the selected date',
                  Icons.info_outline,
                  PiggyColors.warning,
                  PiggyColors.warningSoft,
                ),
                const SizedBox(height: PiggySpace.sm),
                const _Feedback(
                  'Could not save. Try again.',
                  Icons.error_outline,
                  PiggyColors.error,
                  PiggyColors.errorSoft,
                ),
                _section(
                  '10 · Spacing & shape',
                  '간격 4 · 8 · 12 · 16 · 20 · 24 · 32 / 모서리 12 · 16 · 18 · 24',
                ),
                const Text(
                  '기본 좌우 여백 20 pt · 카드 안쪽 16 pt · 큰 그림자와 장식용 그라데이션 없이 색과 간격으로 위계를 만듭니다.',
                  style: PiggyType.caption,
                ),
                const SizedBox(height: PiggySpace.xxl),
              ],
            ),
          ),
        ),
      );

  Widget _section(String title, String detail) => Padding(
        padding:
            const EdgeInsets.only(top: PiggySpace.xxl, bottom: PiggySpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: PiggyType.sectionTitle),
            const SizedBox(height: PiggySpace.sm),
            Text(detail, style: PiggyType.caption),
          ],
        ),
      );
}

class _Swatch extends StatelessWidget {
  final String label;
  final Color color;
  const _Swatch(this.label, this.color);

  String get hex =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(PiggyRadius.small),
                border: Border.all(color: PiggyColors.line),
              ),
            ),
            const SizedBox(height: PiggySpace.xs),
            Text(label, style: PiggyType.label),
            Text(hex, style: PiggyType.metadata),
          ],
        ),
      );
}

class _Feedback extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color foreground;
  final Color background;
  const _Feedback(this.text, this.icon, this.foreground, this.background);

  @override
  Widget build(BuildContext context) => PiggySurface(
        color: background,
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: PiggySpace.sm),
            Expanded(
              child: Text(
                text,
                style: PiggyType.body.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      );
}
