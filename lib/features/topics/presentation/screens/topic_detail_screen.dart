import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/topic_model.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/topic_detail_provider.dart';
import 'topic_edit_screen.dart';

class TopicDetailScreen extends ConsumerWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final int topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topicDetailNotifierProvider(topicId));
    final notifier = ref.read(topicDetailNotifierProvider(topicId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await _openEdit(context, state, notifier);
              ref.read(settingsNotifierProvider.notifier).loadMyPiggies();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _TopicDetailCard(state: state),
          const Divider(indent: 16, endIndent: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Follower List',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _TopicSubscribersList(state: state),
        ],
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    TopicDetailState state,
    TopicDetailNotifier notifier,
  ) async {
    final current = state.topic.value;
    if (current == null) return;
    final updated = await Navigator.push<TopicModel>(
      context,
      MaterialPageRoute(builder: (_) => TopicEditScreen(topic: current)),
    );
    if (updated != null) {
      notifier.updateTopic(updated);
    }
  }
}

class _TopicDetailCard extends StatelessWidget {
  final TopicDetailState state;

  const _TopicDetailCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return state.topic.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (topic) => _TopicProfileCard(
        topic: topic,
        followerCount: state.subscribers.value?.length ?? 0,
      ),
    );
  }
}

class _TopicSubscribersList extends StatelessWidget {
  final TopicDetailState state;

  const _TopicSubscribersList({required this.state});

  @override
  Widget build(BuildContext context) {
    return state.subscribers.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Failed to load subscribers. Please try again.',
          style: TextStyle(color: Colors.red),
        ),
      ),
      data: (subs) => subs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'No subscribers yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final sub = subs[index];
                return ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text(sub.user.nickName),
                );
              },
            ),
    );
  }
}

class _TopicProfileCard extends StatelessWidget {
  final TopicModel topic;
  final int followerCount;

  const _TopicProfileCard({required this.topic, required this.followerCount});

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdDate = DateTime.tryParse(topic.createdAt);
    final createdStr = createdDate != null
        ? '${createdDate.month.toString().padLeft(2, '0')}/${createdDate.day.toString().padLeft(2, '0')}/${createdDate.year}'
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(
            'My Piggy',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            topic.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.savings,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 100, child: _StatItem(label: 'Created', value: createdStr)),
                VerticalDivider(color: theme.dividerColor, width: 48),
                SizedBox(
                    width: 100,
                    child: _StatItem(label: 'Followers', value: _formatCount(followerCount))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}
