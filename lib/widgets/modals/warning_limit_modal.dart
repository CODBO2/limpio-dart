import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

Future<void> showWarningLimitModal(
  BuildContext context, {
  required double? currentLimit,
  required void Function(double? limit) onSave,
}) {
  return showDialog(
    context: context,
    builder: (context) => WarningLimitModal(
      currentLimit: currentLimit,
      onSave: onSave,
    ),
  );
}

class WarningLimitModal extends StatefulWidget {
  const WarningLimitModal({
    super.key,
    required this.currentLimit,
    required this.onSave,
  });

  final double? currentLimit;
  final void Function(double? limit) onSave;

  @override
  State<WarningLimitModal> createState() => _WarningLimitModalState();
}

class _WarningLimitModalState extends State<WarningLimitModal> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentLimit != null ? widget.currentLimit.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      widget.onSave(null);
    } else {
      final num = double.tryParse(trimmed.replaceAll(',', '.'));
      if (num != null) widget.onSave(num);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Límite de advertencia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Si el balance total (en USD) está por debajo de este monto, se mostrará en amarillo.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Text(
              'MONTO LÍMITE (USD)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Ej. 100'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.snackbarDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
