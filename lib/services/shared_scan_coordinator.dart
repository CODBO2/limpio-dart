import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/invoice_scan_draft.dart';
import 'invoice_scanner_service.dart';

/// Coordina el OCR temprano cuando Limpio se abre vía compartir imagen.
class SharedScanCoordinator {
  SharedScanCoordinator._();

  static bool initialHandled = false;
  /// Evita que Bootstrap y SharedImageIntake presenten el flujo a la vez.
  static bool uiSessionActive = false;
  static Future<InvoiceScanDraft>? _inFlight;

  static String? firstImagePath(List<SharedMediaFile> files) {
    for (final file in files) {
      if (file.type == SharedMediaType.image) return file.path;
    }
    return null;
  }

  /// Arranca OCR liviano en paralelo (sin UI).
  static Future<InvoiceScanDraft> startFastScan(String imagePath) {
    final existing = _inFlight;
    if (existing != null) return existing;

    _inFlight = () async {
      final scanner = InvoiceScannerService();
      try {
        return await scanner.scanSharedScreenshot(XFile(imagePath));
      } catch (_) {
        return const InvoiceScanDraft(rawText: '');
      } finally {
        scanner.dispose();
      }
    }();

    return _inFlight!;
  }

  static Future<InvoiceScanDraft>? takeInFlight() {
    final future = _inFlight;
    _inFlight = null;
    return future;
  }

  static InvoiceScanDraft preferBolivaresIfUncertain(InvoiceScanDraft draft) {
    if (draft.currency != null && draft.currencyConfidence >= 0.5) {
      return draft;
    }
    return InvoiceScanDraft(
      rawText: draft.rawText,
      monto: draft.monto,
      currency: 'bolivares',
      date: draft.date,
      amountConfidence: draft.amountConfidence,
      currencyConfidence:
          draft.currency == null ? 0.4 : draft.currencyConfidence,
      dateConfidence: draft.dateConfidence,
    );
  }
}
