import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSupportLink(BuildContext context, String url) async {
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {
    // The device may have no browser or mail app configured.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Could not open $url')),
  );
}
