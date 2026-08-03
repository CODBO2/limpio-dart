import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/invoice_scan_draft.dart';
import 'invoice_image_preprocessor.dart';
import 'invoice_layout_parser.dart';
import 'invoice_text_parser.dart';

class InvoiceScannerService {
  InvoiceScannerService({
    InvoiceLayoutParser? layoutParser,
    InvoiceTextParser? textParser,
    InvoiceImagePreprocessor? preprocessor,
  })  : _layoutParser = layoutParser ?? InvoiceLayoutParser(textParser: textParser),
        _textParser = textParser ?? InvoiceTextParser(),
        _preprocessor = preprocessor ?? InvoiceImagePreprocessor();

  final InvoiceLayoutParser _layoutParser;
  final InvoiceTextParser _textParser;
  final InvoiceImagePreprocessor _preprocessor;
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<InvoiceScanDraft> scanImageFile(XFile file) async {
    // Cede un frame antes del trabajo pesado.
    await Future<void>.delayed(Duration.zero);

    final prepared = await _preprocessor.process(file.path);
    await Future<void>.delayed(Duration.zero);

    final fullDraft = await _scanPath(prepared.fullPath);
    InvoiceScanDraft? bottomDraft;
    if (prepared.bottomPath != null) {
      await Future<void>.delayed(Duration.zero);
      bottomDraft = await _scanPath(prepared.bottomPath!);
    }

    final merged = _mergeDrafts(fullDraft, bottomDraft);

    _tryDelete(prepared.fullPath, keepIf: file.path);
    if (prepared.bottomPath != null) {
      _tryDelete(prepared.bottomPath!, keepIf: file.path);
    }

    return merged;
  }

  /// OCR para capturas compartidas: evita preproceso Dart (causa ANR) y
  /// aplica heurísticas de pago móvil al parsear.
  Future<InvoiceScanDraft> scanSharedScreenshot(XFile file) async {
    await Future<void>.delayed(Duration.zero);

    // Solo redimensiona si el archivo es muy grande; si no, OCR directo.
    final preparedPath = await _preprocessor.processLight(file.path);
    try {
      await Future<void>.delayed(Duration.zero);
      final draft = await _scanPath(preparedPath, preferPagoMovil: true);
      return draft;
    } finally {
      _tryDelete(preparedPath, keepIf: file.path);
    }
  }

  Future<InvoiceScanDraft> scanFile(File file) async {
    return scanImageFile(XFile(file.path));
  }

  Future<InvoiceScanDraft> _scanPath(
    String path, {
    bool preferPagoMovil = false,
  }) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognized = await _recognizer.processImage(inputImage);
    final text = recognized.text.trim();
    if (text.isEmpty) {
      return const InvoiceScanDraft(rawText: '');
    }

    final draft = _layoutParser.parseRecognizedText(recognized);
    if (!preferPagoMovil) return draft;
    return _textParser.refinePagoMovil(draft);
  }

  InvoiceScanDraft _mergeDrafts(
    InvoiceScanDraft full,
    InvoiceScanDraft? bottom,
  ) {
    if (bottom == null) return full;

    final rawText = [
      if (full.rawText.isNotEmpty) '--- FULL ---\n${full.rawText}',
      if (bottom.rawText.isNotEmpty) '--- BOTTOM ---\n${bottom.rawText}',
    ].join('\n\n');

    final preferBottom = bottom.amountConfidence > full.amountConfidence ||
        (bottom.hasAmount && !full.hasAmount);

    final winner = preferBottom ? bottom : full;
    final other = preferBottom ? full : bottom;

    if (!winner.hasAmount && !other.hasAmount) {
      final combined = _textParser.parse('${full.rawText}\n${bottom.rawText}');
      return InvoiceScanDraft(
        rawText: rawText,
        monto: combined.monto,
        currency: combined.currency,
        date: combined.date ?? full.date ?? bottom.date,
        amountConfidence: combined.amountConfidence,
        currencyConfidence: combined.currencyConfidence,
        dateConfidence: combined.dateConfidence,
      );
    }

    return InvoiceScanDraft(
      rawText: rawText,
      monto: winner.monto,
      currency: winner.currency ?? other.currency,
      date: winner.date ?? other.date,
      amountConfidence: winner.amountConfidence,
      currencyConfidence: winner.currencyConfidence > 0
          ? winner.currencyConfidence
          : other.currencyConfidence,
      dateConfidence: winner.dateConfidence > 0
          ? winner.dateConfidence
          : other.dateConfidence,
    );
  }

  void _tryDelete(String path, {required String keepIf}) {
    if (path == keepIf) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  void dispose() {
    _recognizer.close();
  }
}
