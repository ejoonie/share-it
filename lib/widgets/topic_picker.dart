import 'package:flutter/material.dart';

import '../models/topic_model.dart';

/// 토픽 목록에서 "기본" 토픽을 고른다. is_default인 토픽 중 첫 번째,
/// 없으면 목록의 첫 번째 토픽. 목록이 비어 있으면 null.
int? resolveDefaultTopicId(List<TopicModel> topics) {
  if (topics.isEmpty) return null;
  for (final topic in topics) {
    if (topic.isDefault) return topic.id;
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

/// 토픽 선택 바텀시트. 선택하면 [TopicModel]을 반환하고, 닫으면 null.
Future<TopicModel?> showTopicPickerSheet(
  BuildContext context, {
  required List<TopicModel> topics,
  int? selectedTopicId,
}) {
  return showModalBottomSheet<TopicModel>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Topic',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (topics.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text('No topics', style: TextStyle(color: Colors.black45)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: topics.map((topic) {
                    final selected = topic.id == selectedTopicId;
                    return ListTile(
                      title: Text(topic.title),
                      trailing: selected
                          ? const Icon(Icons.check, color: Color(0xFF4CAF50))
                          : null,
                      onTap: () => Navigator.pop(context, topic),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// 선택된 토픽 이름을 보여주고 탭하면 [showTopicPickerSheet]를 여는 작은 칩.
class TopicSelectorChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const TopicSelectorChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
