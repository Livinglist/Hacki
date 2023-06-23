import 'package:flutter/material.dart' show IconData, Icons;

enum ExportDestination {
  qrCode('QR code', icon: Icons.qr_code),
  clipBoard('ClipBoard', icon: Icons.copy);

  const ExportDestination(
    this.label, {
    required this.icon,
  });

  final String label;
  final IconData icon;
}
