import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/styles/palette.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeViewScreen extends StatelessWidget {
  const QrCodeViewScreen({
    required this.data,
    super.key,
  });

  final String data;

  static const String routeName = '/qr-code-view';

  static Route<dynamic> route({required String data}) {
    return MaterialPageRoute<QrCodeViewScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => QrCodeViewScreen(
        data: data,
      ),
    );
  }

  static const int qrCodeVersion = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Palette.transparent,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final QrPainter painter = QrPainter(
                data: data,
                version: qrCodeVersion,
                gapless: true,
              );
              final ByteData? imageData = await painter.toImageData(300);
              if (imageData == null) {
                return;
              }
              await ImageGallerySaver.saveImage(imageData.buffer.asUint8List());
              if (context.mounted) {
                context.showSnackBar(
                  content: 'QR code saved to your photo album.',
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          QrImageView(
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
          ),
        ],
      ),
    );
  }
}
