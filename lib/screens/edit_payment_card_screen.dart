import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/venezuelan_banks.dart';
import '../core/theme/app_colors.dart';
import '../models/payment_card.dart';
import '../widgets/modals/bank_picker_modal.dart';

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

Future<PaymentCardDraft?> pushEditPaymentCardScreen(
  BuildContext context, {
  PaymentCard? editing,
}) {
  return Navigator.of(context).push<PaymentCardDraft>(
    PageRouteBuilder<PaymentCardDraft>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => EditPaymentCardScreen(editing: editing),
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

class EditPaymentCardScreen extends StatefulWidget {
  const EditPaymentCardScreen({super.key, this.editing});

  final PaymentCard? editing;

  @override
  State<EditPaymentCardScreen> createState() => _EditPaymentCardScreenState();
}

class _EditPaymentCardScreenState extends State<EditPaymentCardScreen> {
  static const _defaultColorHex = '#0A0A0A';

  late final TextEditingController _nameController;
  late final TextEditingController _lastFourController;
  late CardKind _kind;
  late String _colorHex;
  late CardCurrencyMode _currencyMode;
  String? _selectedBank;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _lastFourController = TextEditingController(text: editing?.lastFour ?? '');
    _kind = editing?.kind ?? CardKind.debit;
    _colorHex = editing?.colorHex ?? _defaultColorHex;
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
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un nombre o alias para la tarjeta.')),
      );
      return;
    }
    Navigator.of(context).pop(
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Editar tarjeta' : 'Nueva tarjeta',
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
                    'Solo datos no sensibles: alias, tipo, monedas y opcionalmente los últimos 4 dígitos.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nombre / alias',
                            hintText: 'Ej. Visa personal',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _SectionLabel('TIPO'),
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
                        const SizedBox(height: 18),
                        const _SectionLabel('MONEDAS'),
                        const SizedBox(height: 8),
                        for (final mode in CardCurrencyMode.values) ...[
                          _CurrencyModeTile(
                            mode: mode,
                            selected: _currencyMode == mode,
                            onTap: () => setState(() => _currencyMode = mode),
                          ),
                          if (mode != CardCurrencyMode.values.last)
                            const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 18),
                        TextField(
                          controller: _lastFourController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Últimos 4 dígitos (opcional)',
                            hintText: '1234',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _SectionLabel('BANCO'),
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
                    _isEditing ? 'Guardar cambios' : 'Crear tarjeta',
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

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
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
