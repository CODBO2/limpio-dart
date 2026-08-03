import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/venezuelan_banks.dart';
import '../../core/theme/app_colors.dart';
import '../../models/payment_card.dart';
import 'bank_picker_modal.dart';

const _cardColors = [
  '#0A0A0A',
  '#171717',
  '#262626',
  '#404040',
  '#525252',
  '#737373',
];

Future<PaymentCardDraft?> showEditPaymentCardModal(
  BuildContext context, {
  PaymentCard? editing,
}) {
  return showDialog<PaymentCardDraft>(
    context: context,
    builder: (context) => _EditPaymentCardDialog(editing: editing),
  );
}

class PaymentCardDraft {
  const PaymentCardDraft({
    required this.name,
    required this.kind,
    this.lastFour,
    this.bank,
    required this.colorHex,
    required this.currencyMode,
  });

  final String name;
  final CardKind kind;
  final String? lastFour;
  final String? bank;
  final String colorHex;
  final CardCurrencyMode currencyMode;
}

class _EditPaymentCardDialog extends StatefulWidget {
  const _EditPaymentCardDialog({this.editing});

  final PaymentCard? editing;

  @override
  State<_EditPaymentCardDialog> createState() => _EditPaymentCardDialogState();
}

class _EditPaymentCardDialogState extends State<_EditPaymentCardDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _lastFourController;
  late CardKind _kind;
  late String _colorHex;
  late CardCurrencyMode _currencyMode;
  String? _selectedBank;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _lastFourController = TextEditingController(text: editing?.lastFour ?? '');
    _kind = editing?.kind ?? CardKind.debit;
    _colorHex = editing?.colorHex ?? _cardColors.first;
    _currencyMode = editing?.currencyMode ?? CardCurrencyMode.both;
    _selectedBank = editing?.bank ?? VenezuelanBanks.bnc;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastFourController.dispose();
    super.dispose();
  }

  Future<void> _pickBank() async {
    final result = await showBankPickerModal(
      context,
      selectedBank: _selectedBank,
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedBank = result.isEmpty ? null : result;
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      PaymentCardDraft(
        name: name,
        kind: _kind,
        lastFour: _lastFourController.text.trim().isEmpty
            ? null
            : _lastFourController.text.trim(),
        bank: _selectedBank ?? VenezuelanBanks.bnc,
        colorHex: _colorHex,
        currencyMode: _currencyMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        isEditing ? 'Editar tarjeta' : 'Nueva tarjeta',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Solo datos no sensibles: alias, tipo, monedas y opcionalmente los últimos 4 dígitos.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre / alias',
                hintText: 'Ej. Visa personal',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'TIPO',
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
                  child: _KindChip(
                    label: 'Débito',
                    selected: _kind == CardKind.debit,
                    onTap: () => setState(() => _kind = CardKind.debit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KindChip(
                    label: 'Crédito',
                    selected: _kind == CardKind.credit,
                    onTap: () => setState(() => _kind = CardKind.credit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'MONEDAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final mode in CardCurrencyMode.values) ...[
              _CurrencyModeTile(
                mode: mode,
                selected: _currencyMode == mode,
                onTap: () => setState(() => _currencyMode = mode),
              ),
              if (mode != CardCurrencyMode.values.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _lastFourController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Últimos 4 dígitos (opcional)',
                hintText: '1234',
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'BANCO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickBank,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  hintText: 'BNC',
                  suffixIcon: Icon(Icons.account_balance_outlined),
                ),
                child: Text(
                  _selectedBank ?? VenezuelanBanks.bnc,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.green),
          child: Text(isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

class _CurrencyModeTile extends StatelessWidget {
  const _CurrencyModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final CardCurrencyMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.softFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.description,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.textSecondary,
                    ),
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

class _KindChip extends StatelessWidget {
  const _KindChip({
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
