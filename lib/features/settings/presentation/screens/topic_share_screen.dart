import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/bootstrap/providers/bootstrap_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/providers/core_providers.dart';

class TopicShareScreen extends ConsumerStatefulWidget {
  const TopicShareScreen({super.key});

  @override
  ConsumerState<TopicShareScreen> createState() => _TopicShareScreenState();
}

class _TopicShareScreenState extends ConsumerState<TopicShareScreen> {
  bool _isSubscribing = false;

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(bootstrapNotifierProvider);
    final topic = bootstrapState.data?.topic;

    return Scaffold(
      appBar: AppBar(title: const Text('Share Topic')),
      body: topic == null
          ? const _EmptyTopicView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _TopicHeader(topic: topic),
                const SizedBox(height: 24),
                _QrShareCard(shareUrl: _shareUrl(topic.token)),
                const SizedBox(height: 16),
                _UrlShareCard(
                  shareUrl: _shareUrl(topic.token),
                  onCopy: () => _copyUrl(_shareUrl(topic.token)),
                  onShare: () => Share.share(
                    'Subscribe to ${topic.title}: ${_shareUrl(topic.token)}',
                    subject: 'Share It topic invitation',
                  ),
                ),
                const SizedBox(height: 16),
                _SubscribePreviewCard(
                  isLoading: _isSubscribing,
                  onSubscribe: () => _confirmAndSubscribe(topic),
                ),
                const SizedBox(height: 16),
                const _UnavailableShareCard(),
              ],
            ),
    );
  }

  String _shareUrl(String token) {
    final baseUri = Uri.parse(AppConfig.apiBaseUrl);
    return baseUri.replace(path: '/topics/$token').toString();
  }

  Future<void> _copyUrl(String shareUrl) async {
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share URL copied.')),
    );
  }

  Future<void> _confirmAndSubscribe(TopicModel topic) async {
    final shouldSubscribe = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscribe to topic?'),
        content: Text('Subscribe to "${topic.title}" with this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldSubscribe != true) return;
    setState(() => _isSubscribing = true);
    try {
      final authToken = ref.read(tokenStorageProvider).getAuthToken();
      if (authToken == null) {
        throw const ApiException(statusCode: 401, message: 'Not signed in.');
      }
      await ref.read(apiClientProvider).post(
        '/api/v1/topics/${topic.token}/follow',
        const <String, dynamic>{},
        authToken: authToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscribed to topic.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to subscribe: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }
}

class _TopicHeader extends StatelessWidget {
  final TopicModel topic;

  const _TopicHeader({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.topic_outlined),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My topic'),
                  const SizedBox(height: 4),
                  Text(
                    topic.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrShareCard extends StatelessWidget {
  final String shareUrl;

  const _QrShareCard({required this.shareUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('QR Share', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            QrImageView(
              data: shareUrl,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan this QR code to open the subscription link.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlShareCard extends StatelessWidget {
  final String shareUrl;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _UrlShareCard({
    required this.shareUrl,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL Share', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(shareUrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy URL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscribePreviewCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubscribe;

  const _SubscribePreviewCard({
    required this.isLoading,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_add_alt_1_outlined),
        title: const Text('Subscription confirmation'),
        subtitle: const Text(
          'Preview the YES/NO flow used after opening an invitation.',
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: isLoading ? null : onSubscribe,
      ),
    );
  }
}

class _UnavailableShareCard extends StatelessWidget {
  const _UnavailableShareCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.sensors_off_outlined),
        title: Text('Bump Share'),
        subtitle: Text(
          'Not available on this Android build, so QR and URL sharing are provided.',
        ),
      ),
    );
  }
}

class _EmptyTopicView extends StatelessWidget {
  const _EmptyTopicView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No topic is available to share.'),
      ),
    );
  }
}
