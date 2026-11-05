import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/design_system.dart';
import '../../models/expense_model.dart';
import '../../models/topic_filter.dart';
import '../../models/topic_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/expense_provider.dart';

class ExpenseFilterSheet extends ConsumerWidget {
  const ExpenseFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseNotifierProvider);
    final topicsAsync = ref.watch(myViewableTopicsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PiggySpace.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter', style: PiggyType.sectionTitle),
              const SizedBox(height: PiggySpace.md),
              _TypeTile(
                label: 'All',
                selected: state.activeFilter == null,
                onTap: () => _selectType(context, ref, null),
              ),
              _TypeTile(
                label: 'Expense',
                selected: state.activeFilter == ExpenseType.expense,
                onTap: () => _selectType(context, ref, ExpenseType.expense),
              ),
              _TypeTile(
                label: 'Income',
                selected: state.activeFilter == ExpenseType.income,
                onTap: () => _selectType(context, ref, ExpenseType.income),
              ),
              const Divider(height: PiggySpace.xxl),
              _TopicHeader(
                topicsAsync: topicsAsync,
                topicFilter: state.topicFilter,
              ),
              topicsAsync.when(
                data: (topics) => _TopicList(
                  topics: topics,
                  topicFilter: state.topicFilter,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: PiggySpace.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: PiggySpace.lg),
                  child: Text(
                    'Failed to load topics',
                    style: PiggyType.caption.copyWith(color: PiggyColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectType(
    BuildContext context,
    WidgetRef ref,
    ExpenseType? type,
  ) {
    ref.read(expenseNotifierProvider.notifier).filterExpenses(type);
    Navigator.pop(context);
  }
}

class _TypeTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: PiggyColors.accent)
            : null,
        onTap: onTap,
      );
}

class _TopicHeader extends ConsumerWidget {
  final AsyncValue<List<TopicModel>> topicsAsync;
  final TopicFilter topicFilter;

  const _TopicHeader({required this.topicsAsync, required this.topicFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Topics', style: PiggyType.label),
          topicsAsync.maybeWhen(
            data: (topics) {
              if (topics.isEmpty) return const SizedBox.shrink();
              final allSelected = topics.every(
                (topic) => topicFilter.isSelected(topic.id),
              );
              return TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    ref.read(expenseNotifierProvider.notifier).filterByTopics(
                          allSelected
                              ? const TopicFilterNone()
                              : TopicFilterSelected(
                                  topics.map((topic) => topic.id).toSet(),
                                ),
                        ),
                child: Text(allSelected ? 'Unselect All' : 'Select All'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      );
}

class _TopicList extends ConsumerWidget {
  final List<TopicModel> topics;
  final TopicFilter topicFilter;

  const _TopicList({required this.topics, required this.topicFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (topics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: PiggySpace.lg),
        child: Text('No topics', style: PiggyType.caption),
      );
    }

    final allIds = topics.map((topic) => topic.id).toSet();
    return Column(
      children: topics.map((topic) {
        final selected = topicFilter.isSelected(topic.id);
        return CheckboxListTile(
          activeColor: PiggyColors.accent,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(topic.title),
          value: selected,
          onChanged: (checked) {
            final next = switch (topicFilter) {
              TopicFilterAll() => allIds.toSet(),
              TopicFilterNone() => <int>{},
              TopicFilterSelected(:final topicIds) => topicIds.toSet(),
            };
            checked == true ? next.add(topic.id) : next.remove(topic.id);
            ref
                .read(expenseNotifierProvider.notifier)
                .filterByTopics(TopicFilterSelected(next));
          },
        );
      }).toList(),
    );
  }
}
