import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the router's own admin page in the phone's browser.
Future<void> openRouterPage(BuildContext context, String address, {bool https = false}) async {
  final cleaned = address.trim().replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
  var opened = false;

  if (cleaned.isNotEmpty) {
    try {
      final uri = Uri.parse('${https ? 'https' : 'http'}://$cleaned');
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleaned.isEmpty
            ? 'Enter the router address first.'
            : 'Could not open the browser.'),
      ),
    );
  }
}
