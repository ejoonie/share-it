import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSupportLink(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final mode = uri.scheme == 'http' || uri.scheme == 'https'
      ? LaunchMode.inAppBrowserView
      : LaunchMode.externalApplication;

  try {
    if (await launchUrl(
      uri,
      mode: mode,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    )) {
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
