import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'subscribe_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final url = capture.barcodes.firstOrNull?.rawValue;
    if (url == null) return;

    final token = _extractToken(url);
    if (token == null) return;

    _handled = true;
    _controller.stop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SubscribeScreen(topicToken: token)),
    );
  }

  String? _extractToken(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'topics') {
      return segments[1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          _ScanOverlay(),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(color: Colors.black54),
        ),
        Row(
          children: [
            Container(width: 60, color: Colors.black54),
            Container(
              width: MediaQuery.of(context).size.width - 120,
              height: MediaQuery.of(context).size.width - 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Container(width: 60, color: Colors.black54),
          ],
        ),
        Expanded(
          child: Container(
            color: Colors.black54,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 24),
            child: const Text(
              'Place the QR code inside the frame.',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
