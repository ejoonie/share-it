import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PiggyQrCode extends StatelessWidget {
  final String data;
  final double size;
  const PiggyQrCode({super.key, required this.data, this.size = 240});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Piggy invitation QR code',
        image: true,
        child: QrImageView(
          data: data,
          size: size,
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          embeddedImage: const AssetImage('assets/playstore.png'),
          embeddedImageStyle:
              QrEmbeddedImageStyle(size: Size(size * .18, size * .18)),
        ),
      );
}
