import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/navigation/register_transaction_route.dart';
import '../../core/utils/invoice_image_cropper.dart';
import '../../core/utils/scan_permissions.dart';
import '../../models/activity.dart';
import '../../models/invoice_scan_draft.dart';
import '../../models/payment_method.dart';
import '../../screens/register_mode_screen.dart';
import '../../services/invoice_scanner_service.dart';
import 'invoice_scan_review_modal.dart';
import 'register_mode_modal.dart';

Future<void> showRegisterTransactionFlow(
  BuildContext context, {
  Activity? editingItem,
  String? initialTopicId,
  String? topicName,
  bool topicMode = false,
  String? initialCardId,
  PaymentMethod? initialPaymentMethod,
  required FutureOr<void> Function(Activity item) onSave,
}) async {
  if (editingItem != null) {
    await pushRegisterTransactionScreen(
      context,
      RegisterTransactionArgs(
        editingItem: editingItem,
        initialTopicId: initialTopicId,
        topicName: topicName,
        topicMode: topicMode || initialTopicId != null,
        initialCardId: initialCardId,
        initialPaymentMethod: initialPaymentMethod,
        onSave: onSave,
      ),
    );
    return;
  }

  final mode = await pushRegisterModeScreen(context);
  if (!context.mounted || mode == null) return;

  if (mode == RegisterMode.manual) {
    await pushRegisterTransactionScreen(
      context,
      RegisterTransactionArgs(
        initialTopicId: initialTopicId,
        topicName: topicName,
        topicMode: topicMode || initialTopicId != null,
        initialCardId: initialCardId,
        initialPaymentMethod: initialPaymentMethod,
        onSave: onSave,
      ),
    );
    return;
  }

  if (mode == RegisterMode.gallery) {
    await _runGalleryImportFlow(
      context,
      initialTopicId: initialTopicId,
      topicName: topicName,
      topicMode: topicMode || initialTopicId != null,
      initialCardId: initialCardId,
      initialPaymentMethod: initialPaymentMethod,
      onSave: onSave,
    );
    return;
  }

  await _runCameraScanFlow(
    context,
    initialTopicId: initialTopicId,
    topicName: topicName,
    topicMode: topicMode || initialTopicId != null,
    initialCardId: initialCardId,
    initialPaymentMethod: initialPaymentMethod,
    onSave: onSave,
  );
}

/// Procesa una imagen ya disponible (p. ej. compartida desde otra app).
///
/// Extrae monto/moneda/fecha con OCR liviano y abre el formulario.
Future<void> showSharedImageScanFlow(
  BuildContext context, {
  required String imagePath,
  required FutureOr<void> Function(Activity item) onSave,
  Future<InvoiceScanDraft>? precomputedDraft,
  String? initialTopicId,
  String? topicName,
  bool topicMode = false,
}) {
  return processScannedImage(
    context,
    image: XFile(imagePath),
    offerCrop: false,
    fastScan: true,
    precomputedDraft: precomputedDraft,
    analyzingLabel: 'Analizando captura…',
    preferPaymentMethod: PaymentMethod.pagoMovil,
    preferCurrency: 'bolivares',
    initialTopicId: initialTopicId,
    topicName: topicName,
    topicMode: topicMode,
    onSave: onSave,
  );
}

Future<void> _runCameraScanFlow(
  BuildContext context, {
  String? initialTopicId,
  String? topicName,
  bool topicMode = false,
  String? initialCardId,
  PaymentMethod? initialPaymentMethod,
  required FutureOr<void> Function(Activity item) onSave,
}) async {
  while (context.mounted) {
    final granted = await ScanPermissions.ensureCamera();
    if (!context.mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesita permiso de cámara para escanear.'),
        ),
      );
      return;
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!context.mounted) return;
    if (image == null) return;

    final opened = await processScannedImage(
      context,
      image: image,
      offerCrop: true,
      analyzingLabel: 'Analizando factura…',
      initialTopicId: initialTopicId,
      topicName: topicName,
      topicMode: topicMode,
      initialCardId: initialCardId,
      preferPaymentMethod: initialPaymentMethod,
      onSave: onSave,
    );
    if (opened) return;
  }
}

Future<void> _runGalleryImportFlow(
  BuildContext context, {
  String? initialTopicId,
  String? topicName,
  bool topicMode = false,
  String? initialCardId,
  PaymentMethod? initialPaymentMethod,
  required FutureOr<void> Function(Activity item) onSave,
}) async {
  while (context.mounted) {
    final granted = await ScanPermissions.ensureGallery();
    if (!context.mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesita permiso para acceder a la galería.'),
        ),
      );
      return;
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!context.mounted) return;
    if (image == null) return;

    final opened = await processScannedImage(
      context,
      image: image,
      offerCrop: false,
      fastScan: true,
      analyzingLabel: 'Analizando captura…',
      preferPaymentMethod: initialPaymentMethod ?? PaymentMethod.pagoMovil,
      preferCurrency: 'bolivares',
      initialTopicId: initialTopicId,
      topicName: topicName,
      topicMode: topicMode,
      initialCardId: initialCardId,
      onSave: onSave,
    );
    if (opened) return;
  }
}

/// Corre OCR (+ recorte opcional) → revisión → formulario.
///
/// Devuelve `true` si se abrió el formulario (flujo terminado).
Future<bool> processScannedImage(
  BuildContext context, {
  required XFile image,
  bool offerCrop = true,
  bool fastScan = false,
  Future<InvoiceScanDraft>? precomputedDraft,
  String analyzingLabel = 'Analizando imagen…',
  PaymentMethod? preferPaymentMethod,
  String? preferCurrency,
  String? initialTopicId,
  String? topicName,
  bool topicMode = false,
  String? initialCardId,
  required FutureOr<void> Function(Activity item) onSave,
}) async {
  XFile scanTarget = image;
  if (offerCrop) {
    final cropped = await InvoiceImageCropper.cropInvoiceImage(context, image);
    if (!context.mounted) return false;
    if (cropped == null) return false;
    scanTarget = cropped;
  } else {
    final file = File(image.path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la imagen compartida.')),
        );
      }
      return false;
    }
  }

  if (!context.mounted) return false;

  final needsLoadingUi = precomputedDraft == null;
  if (needsLoadingUi) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(analyzingLabel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InvoiceScanDraft draft;
  if (precomputedDraft != null) {
    try {
      draft = await precomputedDraft;
    } catch (_) {
      draft = const InvoiceScanDraft(rawText: '');
    }
  } else {
    final scanner = InvoiceScannerService();
    try {
      draft = fastScan
          ? await scanner.scanSharedScreenshot(scanTarget)
          : await scanner.scanImageFile(scanTarget);
    } catch (_) {
      draft = const InvoiceScanDraft(rawText: '');
    } finally {
      scanner.dispose();
    }
  }

  if (needsLoadingUi && context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  if (!context.mounted) return false;

  // Capturas de pago móvil casi siempre son en Bs si la moneda es incierta.
  if (preferCurrency != null &&
      (draft.currency == null || draft.currencyConfidence < 0.5)) {
    draft = InvoiceScanDraft(
      rawText: draft.rawText,
      monto: draft.monto,
      currency: preferCurrency,
      date: draft.date,
      amountConfidence: draft.amountConfidence,
      currencyConfidence:
          draft.currency == null ? 0.4 : draft.currencyConfidence,
      dateConfidence: draft.dateConfidence,
    );
  }

  final confirmed = await showInvoiceScanReviewModal(context, draft);
  if (!context.mounted || confirmed == null) return false;

  await pushRegisterTransactionScreen(
    context,
    RegisterTransactionArgs(
      initialTopicId: initialTopicId,
      topicName: topicName,
      topicMode: topicMode,
      initialDraft: confirmed,
      initialPaymentMethod: preferPaymentMethod,
      initialCardId: initialCardId,
      onSave: onSave,
    ),
  );
  return true;
}
