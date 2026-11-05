import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import '../models/topic_model.dart';
import '../navigation/piggy_invite.dart';
import '../widgets/piggy_qr_code.dart';
import 'subscribe_screen.dart';

enum InviteMode { text, scan, yours }

class PiggyInviteScreen extends StatefulWidget {
  final TopicModel topic;
  final InviteMode initialMode;
  const PiggyInviteScreen({
    super.key,
    required this.topic,
    required this.initialMode,
  });
  @override
  State<PiggyInviteScreen> createState() => _PiggyInviteScreenState();
}

class _PiggyInviteScreenState extends State<PiggyInviteScreen> {
  late InviteMode _mode = widget.initialMode;
  final _text = TextEditingController();
  final _qrKey = GlobalKey();
  bool _busy = false;
  String? _error;
  String get _url => 'https://sharablepiggy.com/topics/${widget.topic.token}';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _switch(InviteMode mode) => setState(() {
        _mode = mode;
        _error = null;
      });

  Future<void> _search(String value) async {
    final token = piggyInviteToken(value);
    if (token == null) {
      setState(() => _error = 'Enter a Piggy code or invitation link.');
      return;
    }
    if (token == widget.topic.token) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('This is your own Piggy. Share it with someone else.')));
      setState(
        () => _error = 'This is your own Piggy. Share it with someone else.',
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SubscribeScreen(topicToken: token)),
    );
  }

  Future<void> _export({required bool save}) async {
    setState(() => _busy = true);
    try {
      if (save) {
        final boundary =
            _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (data == null) throw StateError('No image');
        await const MethodChannel('com.sharablepiggy.app/qr')
            .invokeMethod<void>('saveQr', data.buffer.asUint8List());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code saved')),
          );
        }
      } else {
        final box = context.findRenderObject() as RenderBox;
        await SharePlus.instance.share(
          ShareParams(
            text: _url,
            title: widget.topic.title,
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              save
                  ? 'Could not save QR. Allow photo access in Settings and try again.'
                  : 'Could not share. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            switch (_mode) {
              InviteMode.text => 'Search by code',
              InviteMode.scan => 'Scan QR code',
              InviteMode.yours => 'Your QR code'
            },
          ),
        ),
        body: SafeArea(
          child: _mode == InviteMode.scan
              ? _Scanner(
                  onCode: _search,
                  onYours: () => _switch(InviteMode.yours),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: _mode == InviteMode.text
                      ? [
                          const SizedBox(height: 24),
                          TextField(
                            controller: _text,
                            autofocus: true,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            decoration: InputDecoration(
                              labelText: 'Piggy code',
                              hintText: 'Paste a code or invite link',
                              errorText: _error,
                            ),
                            onChanged: (_) => setState(() => _error = null),
                            onSubmitted: _search,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Paste the full code or the link shared with you.',
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _text.text.trim().isEmpty
                                ? null
                                : () => _search(_text.text),
                            child: const Text('Search'),
                          ),
                        ]
                      : [
                          const SizedBox(height: 32),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  RepaintBoundary(
                                    key: _qrKey,
                                    child: ColoredBox(
                                      color: Colors.white,
                                      child: LayoutBuilder(
                                        builder: (_, constraints) =>
                                            PiggyQrCode(
                                          data: _url,
                                          size: constraints.maxWidth
                                              .clamp(120, 320),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    widget.topic.title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Your Piggy code',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            widget.topic.token,
                            textAlign: TextAlign.center,
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: widget.topic.token),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy code'),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed:
                                      _busy ? null : () => _export(save: false),
                                  icon: const Icon(Icons.ios_share),
                                  label: const Text('Share'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _busy ? null : () => _export(save: true),
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('Save QR'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed:
                                _busy ? null : () => _switch(InviteMode.scan),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan QR code'),
                          ),
                        ],
                ),
        ),
      );
}

class _Scanner extends StatefulWidget {
  final Future<void> Function(String) onCode;
  final VoidCallback onYours;
  const _Scanner({required this.onCode, required this.onYours});
  @override
  State<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.qrCode],
  );
  bool _handling = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed && !_handling) {
      _controller.start();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _detect(BarcodeCapture capture) async {
    if (_handling) return;
    final values = capture.barcodes.map((b) => b.rawValue).whereType<String>();
    if (values.isEmpty) return;
    final value = values.first;
    if (piggyInviteToken(value) == null) {
      setState(() => _error = 'This QR code is not a Piggy invite.');
      return;
    }
    _handling = true;
    await _controller.stop();
    if (!mounted) return;
    await widget.onCode(value);
    if (!mounted) return;
    setState(() {
      _handling = false;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _detect,
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.no_photography_outlined, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Camera unavailable. Allow camera access in Settings to scan a QR code.',
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () => _controller.start(),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_error ?? 'Point your camera at a Piggy QR code.'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: TextButton.icon(
              onPressed: widget.onYours,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Your QR code'),
            ),
          ),
        ],
      );
}
