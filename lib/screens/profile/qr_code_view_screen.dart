import 'package:flutter/material.dart';
import 'package:hacki/styles/palette.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeViewScreen extends StatelessWidget {
  const QrCodeViewScreen({
    required this.data,
    super.key,
  });

  final String data;

  static const String routeName = 'qr-code-view';

  static const int qrCodeVersion = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Palette.transparent,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: QrImageView(
              data: data,
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              version: qrCodeVersion,
              size: 300,
            ),
          ),
        ],
      ),
    );
  }
}
