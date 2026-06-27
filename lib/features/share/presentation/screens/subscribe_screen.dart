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
  _Status _status = _Status.loading;
  TopicModel? _topic;

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
    setState(() => _status = _Status.loading);
    try {
      final topic = await _repo.fetchByToken(widget.topicToken);
      if (mounted) setState(() { _topic = topic; _status = _Status.idle; });
    } catch (_) {
      if (mounted) setState(() => _status = _Status.notFound);
    }
  }

  Future<void> _subscribe() async {
    setState(() => _status = _Status.subscribing);
    try {
      await _repo.subscribe(widget.topicToken);
      if (mounted) setState(() => _status = _Status.success);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
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
    return switch (_status) {
      _Status.loading => const CircularProgressIndicator(),
      _Status.notFound => _ResultView(
          icon: Icons.search_off,
          iconColor: Colors.red,
          message: 'Topic not found.\nThe link may be invalid or expired.',
          buttonLabel: 'Go Back',
          onButton: () => Navigator.pop(context),
        ),
      _Status.idle => _IdleView(
          topic: _topic!,
          onSubscribe: _subscribe,
          onCancel: () => Navigator.pop(context),
        ),
      _Status.subscribing => const CircularProgressIndicator(),
      _Status.success => _ResultView(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          message: 'Subscribed to "${_topic!.title}"!\nYou can now manage it together.',
          buttonLabel: 'Done',
          onButton: () => Navigator.pop(context),
        ),
      _Status.error => _ResultView(
          icon: Icons.error_outline,
          iconColor: Colors.red,
          message: 'Failed to subscribe.\nPlease try again.',
          buttonLabel: 'Retry',
          onButton: _subscribe,
        ),
    };
  }
}

enum _Status { loading, notFound, idle, subscribing, success, error }

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
