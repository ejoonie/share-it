import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../models/topic_model.dart';

int? resolveDefaultTopicId(List<TopicModel> topics, {int? lastUsedTopicId}) {
  if (topics.isEmpty) return null;
  for (final topic in topics) {
    if (topic.isDefault) return topic.id;
  }
  if (lastUsedTopicId != null &&
      topics.any((topic) => topic.id == lastUsedTopicId)) {
    return lastUsedTopicId;
  }
  return topics.first.id;
}

TopicModel? findTopicById(List<TopicModel> topics, int? id) {
  if (id == null) return null;
  for (final topic in topics) {
    if (topic.id == id) return topic;
  }
  return null;
}

Future<TopicModel?> showTopicPickerSheet(
  BuildContext context, {
  required List<TopicModel> topics,
  int? selectedTopicId,
}) {
  return showModalBottomSheet<TopicModel>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _TopicPickerSheet(
      topics: topics,
      selectedTopicId: selectedTopicId,
    ),
  );
}

class _TopicPickerSheet extends StatelessWidget {
  final List<TopicModel> topics;
  final int? selectedTopicId;

  const _TopicPickerSheet({
    required this.topics,
    required this.selectedTopicId,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PiggySpace.page,
          PiggySpace.xs,
          PiggySpace.page,
          PiggySpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a topic', style: PiggyType.sectionTitle),
            const SizedBox(height: PiggySpace.xs),
            const Text(
              'This transaction will appear in the selected piggy.',
              style: PiggyType.caption,
            ),
            const SizedBox(height: PiggySpace.lg),
            if (topics.isEmpty)
              const PiggySurface(
                color: PiggyColors.card,
                child: Row(
                  children: [
                    Icon(Icons.folder_off_outlined, color: PiggyColors.muted),
                    SizedBox(width: PiggySpace.md),
                    Text('No topics available', style: PiggyType.body),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.52,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: topics.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: PiggySpace.sm),
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final selected = topic.id == selectedTopicId;
                    return _TopicOption(
                      topic: topic,
                      selected: selected,
                      onTap: () => Navigator.pop(context, topic),
                    );
                  },
                ),
              ),
          ],
        ),
      );
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

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? PiggyColors.accentSoft : PiggyColors.card,
        borderRadius: BorderRadius.circular(PiggyRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PiggyRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(PiggySpace.lg),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : PiggyColors.surface,
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
                      Text(topic.title, style: PiggyType.itemTitle),
                      if (topic.isDefault) ...[
                        const SizedBox(height: 2),
                        const Text('Default topic', style: PiggyType.metadata),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected ? PiggyColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? PiggyColors.accent : PiggyColors.muted,
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
      );
}

class TopicSelectorChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const TopicSelectorChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ActionChip(
        onPressed: onTap,
        avatar: const Icon(Icons.savings_outlined, size: 17),
        label: Text(label, overflow: TextOverflow.ellipsis),
        labelStyle: PiggyType.label.copyWith(color: PiggyColors.accent),
        side: BorderSide.none,
        backgroundColor: PiggyColors.accentSoft,
      );
}
