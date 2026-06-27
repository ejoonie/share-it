import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_it/core/models/topic_model.dart';

import '../../core/models/user_model.dart';
import '../../core/providers/core_providers.dart';
import '../../core/repositories/topic_repository.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final int topicId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  AsyncValue<List<UserModel>> _subscribers = const AsyncValue.loading();
  AsyncValue<TopicModel> _topic = const AsyncValue.loading();

  get topicId => widget.topicId;
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
      appBar: AppBar(title: const Text('Topic Detail')),
      body: ListView(
        children: [
          _topicDetailCard(context),
          const Divider(indent: 16, endIndent: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Subscribers',
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
      final list = await repo.fetchSubscribers(
        topicId: topicId,
        page: page,
        limit: limit,
      );
      if (mounted) setState(() => _subscribers = AsyncValue.data(list));
    } catch (e, st) {
      if (mounted) setState(() => _subscribers = AsyncValue.error(e, st));
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
    return Text(_topic.value?.title ?? '');
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
                  title: Text(sub.nickName),
                );
              },
            ),
    );
  }
}
