import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/subscription_repository.dart';

class SubscribeScreen extends ConsumerStatefulWidget {
  final String topicToken;

  const SubscribeScreen({super.key, required this.topicToken});

  @override
  ConsumerState<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends ConsumerState<SubscribeScreen> {
  _Status _status = _Status.idle;

  Future<void> _subscribe() async {
    setState(() => _status = _Status.loading);
    try {
      final apiClient = ref.read(apiClientProvider);
      final authToken =
          ref.read(tokenStorageProvider).getAuthToken();
      if (authToken == null) throw Exception('Login required');

      final repo = SubscriptionRepository(
        apiClient: apiClient,
        authToken: authToken,
      );
      await repo.subscribe(widget.topicToken);
      if (mounted) setState(() => _status = _Status.success);
    } catch (e) {
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
          children: [
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (_status) {
      _Status.idle => _IdleView(
          topicToken: widget.topicToken,
          onSubscribe: _subscribe,
          onCancel: () => Navigator.pop(context),
        ),
      _Status.loading => const Center(child: CircularProgressIndicator()),
      _Status.success => _ResultView(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          message: 'Subscribed!\nYou can now manage this piggy together.',
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

enum _Status { idle, loading, success, error }

class _IdleView extends StatelessWidget {
  final String topicToken;
  final VoidCallback onSubscribe;
  final VoidCallback onCancel;

  const _IdleView({
    required this.topicToken,
    required this.onSubscribe,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.person_add_outlined, size: 72, color: Colors.orange),
        const SizedBox(height: 24),
        Text(
          'You\'re invited!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
        const SizedBox(height: 8),
        Text(
          topicToken,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[400]),
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
