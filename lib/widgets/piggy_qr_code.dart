import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PiggyQrCode extends StatelessWidget {
  final String data;
  final double size;
  const PiggyQrCode({super.key, required this.data, this.size = 240});

  @override
  Widget build(BuildContext context) {
    // Match the reference: a 25% icon with a thin white surround (27% total),
    // measured against the QR matrix without its outer quiet zone.
    final matrixSize = (size - 40).clamp(0.0, double.infinity);
    final badgeSize = matrixSize * .27;
    final iconSize = matrixSize * .25;
    return Semantics(
      label: 'Piggy invitation QR code',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: data,
              size: size,
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
            Container(
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(badgeSize * .22),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(iconSize * .2),
                child: Image.asset(
                  'assets/playstore.png',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
