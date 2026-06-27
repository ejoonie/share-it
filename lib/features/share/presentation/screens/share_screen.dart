import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/bootstrap/providers/bootstrap_provider.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/repositories/topic_repository.dart';
import 'qr_scan_screen.dart';

class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapState = ref.watch(bootstrapNotifierProvider);
    final topic = bootstrapState.data?.topic;

    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share My Piggy')),
        body: const Center(child: Text('Unable to load piggy information.')),
      );
    }

    const baseUrl = 'https://sharablepiggy.com';
    final shareUrl = '$baseUrl/topics/${topic.token}';

    return Scaffold(
      appBar: AppBar(title: const Text('Share My Piggy')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _ScanSection(),
          const SizedBox(height: 16),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 16),
          _EditableTitle(topic: topic),
          const SizedBox(height: 16),
          _QrSection(shareUrl: shareUrl),
          const SizedBox(height: 16),
          _UrlSection(shareUrl: shareUrl),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _EditableTitle extends ConsumerStatefulWidget {
  final dynamic topic;

  const _EditableTitle({required this.topic});

  @override
  ConsumerState<_EditableTitle> createState() => _EditableTitleState();
}

class _EditableTitleState extends ConsumerState<_EditableTitle> {
  bool _saving = false;

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: widget.topic.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Piggy Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Piggy'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle == null ||
        newTitle.isEmpty ||
        newTitle == widget.topic.title) {
      return;
    }

    setState(() => _saving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final authToken = ref.read(tokenStorageProvider).getAuthToken();
      if (authToken == null) throw Exception('Login required');

      final repo = TopicRepository(apiClient: apiClient, authToken: authToken);
      await repo.updateTitle(widget.topic.id, newTitle);

      await ref
          .read(bootstrapNotifierProvider.notifier)
          .retry(ref.read(tokenStorageProvider).getGuestToken() ?? '');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.topic.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.grey,
                    onPressed: _editTitle,
                    tooltip: 'Change Name',
                  ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Invite others to join this shared piggy',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QrSection extends StatelessWidget {
  final String shareUrl;

  const _QrSection({required this.shareUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.qr_code,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'QR Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: shareUrl,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Anyone who scans this QR code can subscribe this shared piggy.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlSection extends StatelessWidget {
  final String shareUrl;

  const _UrlSection({required this.shareUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Share Link',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shareUrl,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Link'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Link copied to clipboard')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(text: shareUrl),
                      );
                    },
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

class _ScanSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Join via QR Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Scan someone else\'s QR code to join their shared piggy.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan with Camera'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QrScanScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
