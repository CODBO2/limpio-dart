import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/invoice_scan_draft.dart';

Future<InvoiceScanDraft?> showInvoiceScanReviewModal(
  BuildContext context,
  InvoiceScanDraft draft,
) {
  return showDialog<InvoiceScanDraft>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _InvoiceScanReviewDialog(draft: draft),
  );
}

class _InvoiceScanReviewDialog extends StatefulWidget {
  const _InvoiceScanReviewDialog({required this.draft});

  final InvoiceScanDraft draft;

  @override
  State<_InvoiceScanReviewDialog> createState() => _InvoiceScanReviewDialogState();
}

class _InvoiceScanReviewDialogState extends State<_InvoiceScanReviewDialog> {
  var _showRawText = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Revisar captura',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(backgroundColor: AppColors.softFill),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Verifica los datos detectados antes de continuar.',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    _ReviewField(label: 'Monto', value: draft.amountLabel),
                    _ReviewField(label: 'Moneda', value: draft.currencyLabel),
                    if (draft.dateLabel != null)
                      _ReviewField(label: 'Fecha', value: draft.dateLabel!),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showRawText = !_showRawText),
                      icon: Icon(_showRawText ? Icons.expand_less : Icons.expand_more),
                      label: Text(_showRawText ? 'Ocultar texto OCR' : 'Ver texto OCR'),
                    ),
                    if (_showRawText)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.softFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          draft.rawText.isEmpty
                              ? 'No se detectó texto en la imagen.'
                              : draft.rawText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context, draft),
                    child: const Text('Usar datos'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Escanear de nuevo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
