import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/money_amount_input.dart';
import '../models/fixed_expense_preset.dart';
import '../models/payment_method.dart';

Future<FixedExpensePresetDraft?> pushEditFixedExpenseScreen(
  BuildContext context, {
  FixedExpensePreset? editing,
}) {
  return Navigator.of(context).push<FixedExpensePresetDraft>(
    PageRouteBuilder<FixedExpensePresetDraft>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => EditFixedExpenseScreen(editing: editing),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    ),
  );
}

class FixedExpensePresetDraft {
  const FixedExpensePresetDraft({
    required this.title,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
  });

  final String title;
  final String amount;
  final String currency;
  final PaymentMethod paymentMethod;
}

class EditFixedExpenseScreen extends StatefulWidget {
  const EditFixedExpenseScreen({super.key, this.editing});

  final FixedExpensePreset? editing;

  @override
  State<EditFixedExpenseScreen> createState() => _EditFixedExpenseScreenState();
}

class _EditFixedExpenseScreenState extends State<EditFixedExpenseScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _currency;
  late PaymentMethod _paymentMethod;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _titleController = TextEditingController(text: editing?.title ?? '');
    final initialAmount = editing == null
        ? 0.0
        : (double.tryParse(editing.amount.replaceAll(',', '.')) ?? 0);
    _amountController = TextEditingController(
      text: MoneyAmountInput.formatDouble(initialAmount),
    );
    _currency = editing?.currency ?? 'USD';
    _paymentMethod = editing?.paymentMethod ?? PaymentMethod.cashUsd;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amountValue = MoneyAmountInput.parse(_amountController.text);
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un concepto para el gasto fijo.')),
      );
      return;
    }
    if (amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un monto mayor a cero.')),
      );
      return;
    }

    Navigator.of(context).pop(
      FixedExpensePresetDraft(
        title: title,
        amount: amountValue.toStringAsFixed(2),
        currency: _currency,
        paymentMethod: _paymentMethod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Editar gasto fijo' : 'Nuevo gasto fijo',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Define un egreso recurrente (por ejemplo «Cajero · 1000 \$»). '
                    'Luego podrás registrarlo con un toque desde el tópico.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Concepto',
                            hintText: 'Ej. Cajero',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.,]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Monto',
                            suffixText: _currency == 'VES' ? 'Bs' : '\$',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'MONEDA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceChip(
                                label: 'Dólares',
                                selected: _currency == 'USD',
                                onTap: () => setState(() {
                                  _currency = 'USD';
                                  if (_paymentMethod == PaymentMethod.cashVes) {
                                    _paymentMethod = PaymentMethod.cashUsd;
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ChoiceChip(
                                label: 'Bolívares',
                                selected: _currency == 'VES',
                                onTap: () => setState(() {
                                  _currency = 'VES';
                                  if (_paymentMethod == PaymentMethod.cashUsd) {
                                    _paymentMethod = PaymentMethod.cashVes;
                                  }
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'MEDIO DE PAGO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final method in PaymentMethod.values)
                              if (method != PaymentMethod.card)
                                _ChoiceChip(
                                  label: method.label,
                                  selected: _paymentMethod == method,
                                  onTap: () =>
                                      setState(() => _paymentMethod = method),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Guardar cambios' : 'Crear gasto fijo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.softFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
