import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/fuente.dart';

Future<void> showEditFuenteModal(
  BuildContext context, {
  required Fuente fuente,
  required void Function(Fuente fuente) onSave,
}) {
  return showDialog(
    context: context,
    builder: (context) => EditFuenteModal(fuente: fuente, onSave: onSave),
  );
}

class EditFuenteModal extends StatefulWidget {
  const EditFuenteModal({
    super.key,
    required this.fuente,
    required this.onSave,
  });

  final Fuente fuente;
  final void Function(Fuente fuente) onSave;

  @override
  State<EditFuenteModal> createState() => _EditFuenteModalState();
}

class _EditFuenteModalState extends State<EditFuenteModal> {
  late final TextEditingController _nombreController;
  late final TextEditingController _montoController;
  late final TextEditingController _diaController;
  late String _moneda;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.fuente.name);
    _montoController = TextEditingController(text: widget.fuente.amount);
    _diaController = TextEditingController(text: widget.fuente.day.toString());
    _moneda = widget.fuente.currency;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _diaController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nombreController.text.trim();
    final amount = _montoController.text.trim();
    final day = int.tryParse(_diaController.text.trim()) ?? 0;
    if (name.isEmpty || amount.isEmpty || day < 1 || day > 31) return;

    widget.onSave(widget.fuente.copyWith(
      name: name,
      amount: amount,
      currency: _moneda,
      day: day,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Actualizar fuente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('NOMBRE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(hintText: 'Nombre (ej. Salario)'),
              ),
              const SizedBox(height: 16),
              const Text('MONTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'Monto'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => setState(() => _moneda = _moneda == 'USD' ? 'VES' : 'USD'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_moneda == 'USD' ? '\$' : 'VES'),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'DÍA DE COBRO (1-31)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _diaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Día'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.snackbarDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Actualizar', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
