import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/design_system.dart';
import '../../models/expense_model.dart';
import '../../models/topic_filter.dart';
import '../../models/topic_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/expense_provider.dart';

class ExpenseFilterSheet extends ConsumerStatefulWidget {
  const ExpenseFilterSheet({super.key});

  @override
  ConsumerState<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends ConsumerState<ExpenseFilterSheet> {
  late ExpenseType? _type;
  late TopicFilter _topicFilter;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(expenseNotifierProvider);
    _type = state.activeFilter;
    _topicFilter = state.topicFilter;
  }

  void _reset() => setState(() {
        _type = null;
        _topicFilter = const TopicFilterAll();
      });

  void _selectAllTopics() => setState(() {
        _topicFilter = const TopicFilterAll();
      });

  void _clearTopics() => setState(() {
        _topicFilter = const TopicFilterNone();
      });

  void _toggleTopic(TopicModel topic, List<TopicModel> topics) {
    final selectedIds = topics
        .where((item) => _topicFilter.isSelected(item.id))
        .map((item) => item.id)
        .toSet();
    _topicFilter.isSelected(topic.id)
        ? selectedIds.remove(topic.id)
        : selectedIds.add(topic.id);

    setState(() {
      if (selectedIds.isEmpty) {
        _topicFilter = const TopicFilterNone();
      } else if (selectedIds.length == topics.length) {
        _topicFilter = const TopicFilterAll();
      } else {
        _topicFilter = TopicFilterSelected(selectedIds);
      }
    });
  }

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);
    final notifier = ref.read(expenseNotifierProvider.notifier);
    notifier.filterExpenses(_type);
    await notifier.filterByTopics(_topicFilter);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(myViewableTopicsProvider);
    final height = math.min(MediaQuery.sizeOf(context).height * 0.82, 720.0);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            _SheetHeader(onClose: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  PiggySpace.page,
                  PiggySpace.sm,
                  PiggySpace.page,
                  PiggySpace.xl,
                ),
                children: [
                  const _SectionHeading(
                    title: 'Transaction type',
                    description: 'Choose one type or keep everything visible.',
                  ),
                  const SizedBox(height: PiggySpace.md),
                  _TypeSelector(
                    value: _type,
                    onChanged: (value) => setState(() => _type = value),
                  ),
                  const SizedBox(height: PiggySpace.xl),
                  topicsAsync.when(
                    data: (topics) => _TopicSection(
                      topics: topics,
                      filter: _topicFilter,
                      onSelectAll: _selectAllTopics,
                      onClear: _clearTopics,
                      onToggle: (topic) => _toggleTopic(topic, topics),
                    ),
                    loading: () => const _TopicLoadingState(),
                    error: (_, __) => _TopicErrorState(
                      onRetry: () => ref.invalidate(myViewableTopicsProvider),
                    ),
                  ),
                ],
              ),
            ),
            _SheetActions(
              applying: _applying,
              onReset: _reset,
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _SheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PiggySpace.page,
          PiggySpace.xs,
          PiggySpace.xs,
          PiggySpace.sm,
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter transactions', style: PiggyType.sectionTitle),
                  SizedBox(height: 2),
                  Text(
                    'Refine this day and the monthly calendar.',
                    style: PiggyType.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close filters',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String description;

  const _SectionHeading({required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PiggyType.itemTitle),
          const SizedBox(height: 3),
          Text(description, style: PiggyType.caption),
        ],
      );
}

class _TypeSelector extends StatelessWidget {
  final ExpenseType? value;
  final ValueChanged<ExpenseType?> onChanged;

  const _TypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _TypeOption(
              label: 'All',
              icon: Icons.receipt_long_outlined,
              tone: PiggyTone.brand,
              selected: value == null,
              onTap: () => onChanged(null),
            ),
          ),
          const SizedBox(width: PiggySpace.sm),
          Expanded(
            child: _TypeOption(
              label: 'Expenses',
              icon: Icons.north_east_rounded,
              tone: PiggyTone.expense,
              selected: value == ExpenseType.expense,
              onTap: () => onChanged(ExpenseType.expense),
            ),
          ),
          const SizedBox(width: PiggySpace.sm),
          Expanded(
            child: _TypeOption(
              label: 'Income',
              icon: Icons.south_west_rounded,
              tone: PiggyTone.income,
              selected: value == ExpenseType.income,
              onTap: () => onChanged(ExpenseType.income),
            ),
          ),
        ],
      );
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final PiggyTone tone;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? PiggyColors.accentSoft : PiggyColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PiggyRadius.card),
            side: BorderSide(
              color: selected ? PiggyColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PiggyRadius.card),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PiggySpace.xs,
                vertical: PiggySpace.md,
              ),
              child: Column(
                children: [
                  Icon(icon, size: 20, color: tone.foreground),
                  const SizedBox(height: PiggySpace.sm),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PiggyType.label.copyWith(
                      color:
                          selected ? PiggyColors.accent : PiggyColors.secondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _TopicSection extends StatelessWidget {
  final List<TopicModel> topics;
  final TopicFilter filter;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final ValueChanged<TopicModel> onToggle;

  const _TopicSection({
    required this.topics,
    required this.filter,
    required this.onSelectAll,
    required this.onClear,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        topics.where((topic) => filter.isSelected(topic.id)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _SectionHeading(
                title: 'Piggies',
                description: 'Choose where transactions come from.',
              ),
            ),
            if (topics.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: PiggyColors.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$selectedCount of ${topics.length}',
                  style: PiggyType.metadata.copyWith(
                    color: PiggyColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        if (topics.isEmpty) ...[
          const SizedBox(height: PiggySpace.md),
          const _EmptyTopicsState(),
        ] else ...[
          const SizedBox(height: PiggySpace.sm),
          Row(
            children: [
              TextButton(
                onPressed: onSelectAll,
                child: const Text('Select all'),
              ),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
          const SizedBox(height: PiggySpace.xs),
          ...topics.map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: PiggySpace.sm),
              child: _TopicOption(
                topic: topic,
                selected: filter.isSelected(topic.id),
                onTap: () => onToggle(topic),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TopicOption extends StatelessWidget {
  final TopicModel topic;
  final bool selected;
  final VoidCallback onTap;

  const _TopicOption({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  String? get _metadata {
    if (topic.isOwner) return topic.isDefault ? 'Yours · Default' : 'Yours';
    if (topic.ownerName case final owner? when owner.trim().isNotEmpty) {
      return 'By $owner';
    }
    if (topic.isDefault) return 'Default';
    return null;
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? PiggyColors.accentSoft : PiggyColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PiggyRadius.card),
            side: BorderSide(
              color: selected
                  ? PiggyColors.accent.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PiggyRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(PiggySpace.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PiggyColors.surface,
                      borderRadius: BorderRadius.circular(PiggyRadius.small),
                    ),
                    child: Icon(
                      Icons.savings_outlined,
                      size: 20,
                      color:
                          selected ? PiggyColors.accent : PiggyColors.secondary,
                    ),
                  ),
                  const SizedBox(width: PiggySpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PiggyType.itemTitle,
                        ),
                        if (_metadata case final metadata?) ...[
                          const SizedBox(height: 2),
                          Text(
                            metadata,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PiggyType.metadata,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: PiggySpace.sm),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected ? PiggyColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selected ? PiggyColors.accent : PiggyColors.muted,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _TopicLoadingState extends StatelessWidget {
  const _TopicLoadingState();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Piggies',
            description: 'Choose where transactions come from.',
          ),
          SizedBox(height: PiggySpace.xl),
          Center(child: CircularProgressIndicator()),
        ],
      );
}

class _TopicErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _TopicErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Piggies',
            description: 'Choose where transactions come from.',
          ),
          const SizedBox(height: PiggySpace.md),
          PiggySurface(
            color: PiggyColors.errorSoft,
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: PiggyColors.error,
                ),
                const SizedBox(width: PiggySpace.md),
                const Expanded(
                  child: Text(
                    'Couldn’t load your piggies.',
                    style: PiggyType.body,
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ],
      );
}

class _EmptyTopicsState extends StatelessWidget {
  const _EmptyTopicsState();

  @override
  Widget build(BuildContext context) => const PiggySurface(
        color: PiggyColors.card,
        child: Row(
          children: [
            Icon(Icons.savings_outlined, color: PiggyColors.muted),
            SizedBox(width: PiggySpace.md),
            Expanded(
              child: Text('No piggies available yet.', style: PiggyType.body),
            ),
          ],
        ),
      );
}

class _SheetActions extends StatelessWidget {
  final bool applying;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const _SheetActions({
    required this.applying,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: PiggyColors.surface,
          border: Border(top: BorderSide(color: PiggyColors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PiggySpace.page,
            PiggySpace.md,
            PiggySpace.page,
            PiggySpace.sm,
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: applying ? null : onReset,
                child: const Text('Reset'),
              ),
              const SizedBox(width: PiggySpace.sm),
              Expanded(
                child: FilledButton(
                  onPressed: applying ? null : onApply,
                  child: applying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      );
}
