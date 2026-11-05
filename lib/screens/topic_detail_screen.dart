import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/topic_model.dart';
import '../providers/settings_provider.dart';
import '../providers/topic_detail_provider.dart';
import 'topic_edit_screen.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});
  final int topicId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  bool _unfollowing = false;
  bool _deleting = false;

  String _date(DateTime? date) => date == null
      ? 'Not available'
      : DateFormat.yMMMd().format(date.toLocal());

  Future<void> _toggleFollow(TopicModel topic, {bool undo = false}) async {
    if (!mounted || _unfollowing) return;
    final following =
        ref.read(topicDetailNotifierProvider(widget.topicId)).isFollowing;
    if (undo && following) return;
    setState(() => _unfollowing = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final notifier =
        ref.read(topicDetailNotifierProvider(widget.topicId).notifier);
    final success =
        following ? await notifier.unfollow() : await notifier.follow();
    if (!mounted) return;
    setState(() => _unfollowing = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not update follow status. Please try again.'),
      ),);
    } else if (following) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unfollowed ${topic.title}'),
        action: SnackBarAction(
            label: 'Undo', onPressed: () => _toggleFollow(topic, undo: true),),
      ),);
    }
  }

  Future<void> _delete(TopicModel topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${topic.title}?'),
        content: const Text(
          'This piggy and its entries will no longer be available to you or its followers. This cannot be undone in the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    final deleted = await ref
        .read(topicDetailNotifierProvider(widget.topicId).notifier)
        .deleteTopic();
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context);
    } else {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete this piggy. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(topicDetailNotifierProvider(widget.topicId));
    final notifier =
        ref.read(topicDetailNotifierProvider(widget.topicId).notifier);
    final topic = state.topic.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piggy details'),
        actions: [
          if (topic?.isOwner == true)
            IconButton(
              tooltip: 'Edit piggy',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.push<TopicModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicEditScreen(topic: topic!),
                  ),
                );
                if (!mounted || updated == null) return;
                notifier.updateTopic(updated);
                ref.read(settingsNotifierProvider.notifier).loadMyPiggies();
              },
            ),
        ],
      ),
      body: state.topic.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load this piggy.'),
              TextButton(
                onPressed: notifier.loadTopic,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (topic) => RefreshIndicator(
          onRefresh: notifier.loadTopic,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.savings_outlined,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                topic.title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                topic.isOwner
                    ? 'Your piggy'
                    : (state.isFollowing ? 'Following' : 'Not following'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(topic.isOwner ? 'Owner (you)' : 'Owner'),
                      subtitle: Text(topic.ownerName ?? 'Not available'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(topic.isOwner
                          ? 'Created'
                          : (state.isFollowing
                              ? 'Followed on'
                              : 'Previously followed on'),),
                      subtitle: Text(
                        _date(
                          topic.isOwner
                              ? DateTime.tryParse(topic.createdAt)
                              : topic.followedAt,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (topic.isOwner) ...[
                const SizedBox(height: 28),
                Text(
                  'Followers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                state.subscribers.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Column(
                    children: [
                      const Text('Could not load followers.'),
                      TextButton(
                        onPressed: notifier.loadSubscribers,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                  data: (followers) => followers.isEmpty
                      ? const Text('No followers yet.')
                      : Column(
                          children: followers
                              .map(
                                (f) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: const Icon(Icons.person_outline),
                                    title: Text(f.user.nickName),
                                    subtitle:
                                        Text('Followed ${_date(f.followedAt)}'),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _deleting ? null : () => _delete(topic),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(_deleting ? 'Deleting…' : 'Delete piggy'),
                ),
              ] else ...[
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _unfollowing ? null : () => _toggleFollow(topic),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: state.isFollowing
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  icon: _unfollowing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(state.isFollowing
                          ? Icons.person_remove_outlined
                          : Icons.person_add_outlined,),
                  label: Text(_unfollowing
                      ? 'Updating…'
                      : (state.isFollowing ? 'Unfollow' : 'Follow'),),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
