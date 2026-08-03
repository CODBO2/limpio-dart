import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class InvoiceImagePreprocessor {
  static const int maxSide = 1600;
  static const int maxSideLight = 1280;
  /// Por encima de esto conviene reducir (bytes) antes de OCR.
  static const int lightResizeMinBytes = 2 * 1024 * 1024;

  /// Enhances contrast/sharpness and optionally returns a bottom crop path.
  /// Corre en isolate para no bloquear el UI (evita ANR).
  Future<PreprocessedInvoiceImages> process(String sourcePath) async {
    final result = await compute(_processIsolate, sourcePath);
    return PreprocessedInvoiceImages(
      fullPath: result['fullPath']!,
      bottomPath: result['bottomPath'],
    );
  }

  /// Preproceso mínimo para capturas. Si la imagen no es enorme, no toca el
  /// archivo (ML Kit ya escala) — evita decode/encode en Dart que congela la app.
  Future<String> processLight(String sourcePath) async {
    try {
      final length = await File(sourcePath).length();
      if (length < lightResizeMinBytes) return sourcePath;
    } catch (_) {
      return sourcePath;
    }
    return compute(_processLightIsolate, sourcePath);
  }
}

Map<String, String?> _processIsolate(String sourcePath) {
  final bytes = File(sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return {'fullPath': sourcePath, 'bottomPath': null};
  }

  var image = decoded;
  final longest = math.max(image.width, image.height);
  if (longest > InvoiceImagePreprocessor.maxSide) {
    final scale = InvoiceImagePreprocessor.maxSide / longest;
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  image = img.grayscale(image);
  image = img.adjustColor(image, contrast: 1.2, brightness: 1.04);

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final fullPath = '${Directory.systemTemp.path}/invoice_prep_$stamp.jpg';
  File(fullPath).writeAsBytesSync(img.encodeJpg(image, quality: 85));

  final bottomTop = (image.height * 0.55).round();
  final bottomHeight = image.height - bottomTop;
  String? bottomPath;
  if (bottomHeight > 40) {
    final bottom = img.copyCrop(
      image,
      x: 0,
      y: bottomTop,
      width: image.width,
      height: bottomHeight,
    );
    bottomPath = '${Directory.systemTemp.path}/invoice_prep_bottom_$stamp.jpg';
    File(bottomPath).writeAsBytesSync(img.encodeJpg(bottom, quality: 85));
  }

  return {'fullPath': fullPath, 'bottomPath': bottomPath};
}

String _processLightIsolate(String sourcePath) {
  final bytes = File(sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return sourcePath;

  var image = decoded;
  final longest = math.max(image.width, image.height);
  if (longest <= InvoiceImagePreprocessor.maxSideLight) return sourcePath;

  final scale = InvoiceImagePreprocessor.maxSideLight / longest;
  image = img.copyResize(
    image,
    width: (image.width * scale).round(),
    height: (image.height * scale).round(),
    interpolation: img.Interpolation.linear,
  );

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final path = '${Directory.systemTemp.path}/share_prep_$stamp.jpg';
  File(path).writeAsBytesSync(img.encodeJpg(image, quality: 82));
  return path;
}

class PreprocessedInvoiceImages {
  const PreprocessedInvoiceImages({
    required this.fullPath,
    required this.bottomPath,
  });

  final String fullPath;
  final String? bottomPath;
}
