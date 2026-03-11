enum ImportSource {
  qrCode('QR Code'),
  file('From File');

  const ImportSource(
    this.uiLabel,
  );

  final String uiLabel;
}
