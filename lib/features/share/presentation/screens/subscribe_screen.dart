import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/topic_model.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/subscription_repository.dart';

class SubscribeScreen extends ConsumerStatefulWidget {
  final String topicToken;

  const SubscribeScreen({super.key, required this.topicToken});

  @override
  ConsumerState<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends ConsumerState<SubscribeScreen> {
  AsyncValue<TopicModel> _topicState = const AsyncValue.loading();
  AsyncValue<void>? _subscribeState; // null = 아직 시도 안 함

  @override
  void initState() {
    super.initState();
    _fetchTopic();
  }

  SubscriptionRepository get _repo {
    final authToken = ref.read(tokenStorageProvider).getAuthToken();
    return SubscriptionRepository(
      apiClient: ref.read(apiClientProvider),
      authToken: authToken ?? '',
    );
  }

  Future<void> _fetchTopic() async {
    setState(() => _topicState = const AsyncValue.loading());
    try {
      final topic = await _repo.fetchByToken(widget.topicToken);
      if (mounted) setState(() => _topicState = AsyncValue.data(topic));
    } catch (e, st) {
      if (mounted) setState(() => _topicState = AsyncValue.error(e, st));
    }
  }

  Future<void> _subscribe(TopicModel topic) async {
    setState(() => _subscribeState = const AsyncValue.loading());
    try {
      await _repo.subscribe(widget.topicToken);
      if (mounted) setState(() => _subscribeState = const AsyncValue.data(null));
    } catch (e, st) {
      if (mounted) setState(() => _subscribeState = AsyncValue.error(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildContent()],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // 구독 시도 후 상태
    final sub = _subscribeState;
    if (sub != null) {
      return sub.when(
        loading: () => const CircularProgressIndicator(),
        data: (_) => _topicState.maybeWhen(
          data: (topic) => _ResultView(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            message: 'Subscribed to "${topic.title}"!\nYou can now manage it together.',
            buttonLabel: 'Done',
            onButton: () => Navigator.pop(context),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        error: (_, __) => _ResultView(
          icon: Icons.error_outline,
          iconColor: Colors.red,
          message: 'Failed to subscribe.\nPlease try again.',
          buttonLabel: 'Retry',
          onButton: () => _topicState.whenData((t) => _subscribe(t)),
        ),
      );
    }

    // 토픽 조회 상태
    return _topicState.when(
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => _ResultView(
        icon: Icons.search_off,
        iconColor: Colors.red,
        message: 'Topic not found.\nThe link may be invalid or expired.',
        buttonLabel: 'Go Back',
        onButton: () => Navigator.pop(context),
      ),
      data: (topic) => _IdleView(
        topic: topic,
        onSubscribe: () => _subscribe(topic),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  final TopicModel topic;
  final VoidCallback onSubscribe;
  final VoidCallback onCancel;

  const _IdleView({
    required this.topic,
    required this.onSubscribe,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.savings_outlined, size: 72, color: Colors.orange),
        const SizedBox(height: 24),
        Text(
          topic.title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Subscribe to this piggy and manage it together.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onSubscribe,
            child: const Text('Subscribe'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final String buttonLabel;
  final VoidCallback onButton;

  const _ResultView({
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.buttonLabel,
    required this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 72, color: iconColor),
        const SizedBox(height: 24),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onButton,
            child: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}
