import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PiggyQrCode extends StatelessWidget {
  final String data;
  final double size;

  const PiggyQrCode({super.key, required this.data, this.size = 200});

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
            QrImageView(data: data, version: QrVersions.auto, size: size),
            const SizedBox(height: 12),
            Text(
              'Scan this QR code to subscribe.',
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
