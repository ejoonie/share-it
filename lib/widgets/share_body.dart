import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/bootstrap_provider.dart';
import '../models/topic_model.dart';
import '../providers/core_providers.dart';
import '../screens/subscribe_screen.dart';
import 'piggy_qr_code.dart';
import 'share_url_card.dart';

class ShareBody extends ConsumerStatefulWidget {
  const ShareBody({super.key});

  @override
  ConsumerState<ShareBody> createState() => _ShareBodyState();
}

class _ShareBodyState extends ConsumerState<ShareBody> {
  TopicModel? _topic;
  bool _saving = false;
  bool _scannerOpen = false;
  bool _handled = false;
  final _scannerController = MobileScannerController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _topic ??= ref.read(bootstrapNotifierProvider).data?.topic;
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _editTitle(String currentTitle, int topicId) async {
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Piggy'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Piggy name'),
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

    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) return;

    setState(() => _saving = true);
    try {
      await ref.read(topicRepositoryProvider).update(topicId, title: newTitle);

      if (mounted) setState(() => _topic = _topic!.copyWith(title: newTitle));
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

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final url = capture.barcodes.firstOrNull?.rawValue;
    if (url == null) return;
    final token = _extractToken(url);
    if (token == null) return;

    _handled = true;
    _scannerController.stop();
    setState(() => _scannerOpen = false);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SubscribeScreen(topicToken: token)),
    );
  }

  String? _extractToken(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'topics') return segments[1];
    return null;
  }

  Future<void> _debugSubscribe() async {
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('[Debug] Enter Topic Token'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'topic token'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Go'),
          ),
        ],
      ),
    );
    if (token == null || token.isEmpty) return;
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SubscribeScreen(topicToken: token)),
      );
    }
  }

  void _toggleScanner() {
    setState(() {
      _scannerOpen = !_scannerOpen;
      _handled = false;
      if (_scannerOpen) {
        _scannerController.start();
      } else {
        _scannerController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;
    if (topic == null) {
      return const Center(child: Text('Unable to load piggy information.'));
    }

    const baseUrl = 'https://sharablepiggy.com';
    final shareUrl = '$baseUrl/topics/${topic.token}';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _ScanSection(
          isOpen: _scannerOpen,
          controller: _scannerController,
          onToggle: _toggleScanner,
          onDetect: _onDetect,
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.bug_report_outlined, size: 16),
            label: const Text('[Debug] Enter token manually'),
            onPressed: _debugSubscribe,
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(indent: 16, endIndent: 16),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              topic.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.grey,
                    tooltip: 'Rename',
                    onPressed: () => _editTitle(topic.title, topic.id),
                  ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Invite others to join this piggy',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        PiggyQrCode(data: shareUrl),
        const SizedBox(height: 16),
        ShareUrlCard(url: shareUrl),
      ],
    );
  }
}

class _ScanSection extends StatelessWidget {
  final bool isOpen;
  final MobileScannerController controller;
  final VoidCallback onToggle;
  final void Function(BarcodeCapture) onDetect;

  const _ScanSection({
    required this.isOpen,
    required this.controller,
    required this.onToggle,
    required this.onDetect,
  });

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
                  'Scan to Subscribe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isOpen) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 260,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: onDetect,
                      ),
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.orange, width: 3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onToggle,
                  child: const Text('Close Scanner'),
                ),
              ),
            ] else ...[
              Text(
                "Scan someone else's QR code to subscribe.",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Open Camera'),
                  onPressed: onToggle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
