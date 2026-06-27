import 'package:flutter/material.dart';

import '../widgets/share_body.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share')),
      body: const ShareBody(),
    );
  }
}
