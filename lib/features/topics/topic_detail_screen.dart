import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/topic_follow_model.dart';
import '../../core/models/topic_model.dart';
import '../../core/providers/core_providers.dart';
import '../../core/repositories/topic_repository.dart';
import 'topic_edit_screen.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final int topicId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  AsyncValue<List<TopicFollowModel>> _subscribers = const AsyncValue.loading();
  AsyncValue<TopicModel> _topic = const AsyncValue.loading();

  int get topicId => widget.topicId;
  int page = 1;
  int limit = 10;

  @override
  void initState() {
    super.initState();
    _loadTopic();
    _loadTopicSubscribers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEdit(),
          ),
        ],
      ),
      body: ListView(
        children: [
          _topicDetailCard(context),
          const Divider(indent: 16, endIndent: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Follower List',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _topicSubscribersList(context),
        ],
      ),
    );
  }

  Future<void> _loadTopicSubscribers({bool loadMore = false}) async {
    final authToken = ref.read(tokenStorageProvider).getAuthToken();
    if (authToken == null) return;

    setState(() => _subscribers = const AsyncValue.loading());
    if (loadMore) {
      page += 1;
    } else {
      page = 1;
    }

    try {
      final repo = TopicRepository(
        apiClient: ref.read(apiClientProvider),
        authToken: authToken,
      );
      final list = await repo.fetchFollows(
        topicId: topicId,
        page: page,
        limit: limit,
      );
      if (mounted) setState(() => _subscribers = AsyncValue.data(list));
    } catch (e, st) {
      debugPrint('fetchSubscribers error: $e');
      debugPrint('$st');
      if (mounted) setState(() => _subscribers = AsyncValue.error(e, st));
    }
  }

  Future<void> _openEdit() async {
    final current = _topic.value;
    if (current == null) return;
    final updated = await Navigator.push<TopicModel>(
      context,
      MaterialPageRoute(builder: (_) => TopicEditScreen(topic: current)),
    );
    if (updated != null && mounted) {
      setState(() => _topic = AsyncValue.data(updated));
    }
  }

  Future<void> _loadTopic() async {
    final authToken = ref.read(tokenStorageProvider).getAuthToken();
    if (authToken == null) return;

    setState(() => _topic = const AsyncValue.loading());
    try {
      final repo = TopicRepository(
        apiClient: ref.read(apiClientProvider),
        authToken: authToken,
      );
      final t = await repo.fetchById(topicId);
      if (mounted) setState(() => _topic = AsyncValue.data(t));
    } catch (e, st) {
      if (mounted) setState(() => _topic = AsyncValue.error(e, st));
    }
  }

  Widget _topicDetailCard(BuildContext context) {
    return _topic.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (topic) => _TopicProfileCard(
        topic: topic,
        followerCount: _subscribers.value?.length ?? 0,
      ),
    );
  }

  Widget _topicSubscribersList(BuildContext context) {
    return _subscribers.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
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
          // 타이틀
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
          // 로고
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
          // 통계
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 100, child: _StatItem(label: 'Created', value: createdStr)),
                VerticalDivider(color: theme.dividerColor, width: 48),
                SizedBox(width: 100, child: _StatItem(label: 'Followers', value: _formatCount(followerCount))),
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
