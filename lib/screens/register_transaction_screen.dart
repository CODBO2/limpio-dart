import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/defaults.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/money_amount_input.dart';
import '../core/navigation/register_transaction_route.dart';
import '../models/activity.dart';
import '../models/activity_builder.dart';
import '../models/invoice_scan_draft.dart';
import '../models/payment_card.dart';
import '../models/payment_method.dart';
import '../models/rate_type.dart';
import '../providers/activities_provider.dart';
import '../providers/app_providers.dart';
import '../providers/cards_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/topics_provider.dart';
import '../providers/tutorial_provider.dart';

Future<void> showRegisterTransactionScreen(
  BuildContext context, {
  Activity? editingItem,
  String? initialTopicId,
  String? topicName,
  bool topicMode = false,
  InvoiceScanDraft? initialDraft,
  required FutureOr<void> Function(Activity item) onSave,
}) {
  return pushRegisterTransactionScreen(
    context,
    RegisterTransactionArgs(
      editingItem: editingItem,
      initialTopicId: initialTopicId,
      topicName: topicName,
      topicMode: topicMode || initialTopicId != null,
      initialDraft: initialDraft,
      onSave: onSave,
    ),
  );
}

class RegisterTransactionScreen extends ConsumerStatefulWidget {
  const RegisterTransactionScreen({
    super.key,
    this.editingItem,
    this.initialTopicId,
    this.topicName,
    this.topicMode = false,
    this.initialDraft,
    this.initialPaymentMethod,
    this.initialCardId,
    required this.onSave,
  });

  static const routeName = '/register/transaction';

  final Activity? editingItem;
  final String? initialTopicId;
  final String? topicName;
  final bool topicMode;
  final InvoiceScanDraft? initialDraft;
  final PaymentMethod? initialPaymentMethod;
  final String? initialCardId;
  final FutureOr<void> Function(Activity item) onSave;

  @override
  ConsumerState<RegisterTransactionScreen> createState() =>
      _RegisterTransactionScreenState();
}

class _RegisterTransactionScreenState extends ConsumerState<RegisterTransactionScreen> {
  String _currency = 'dollars';
  bool _isIncome = false;
  bool _useCurrentDateTime = true;
  PaymentMethod _paymentMethod = PaymentMethod.pagoMovil;
  String? _selectedCardId;
  String? _selectedTopicId;
  late DateTime _recordedAt;
  double? _rateForDate;
  bool _rateForDateLoading = false;
  bool _rateFromHistory = false;
  int _rateRequestId = 0;

  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController(
    text: MoneyAmountInput.formatCents(0),
  );
  final _customRateController = TextEditingController();
  final _montoFocus = FocusNode();
  bool _conceptoAsList = false;

  @override
  void initState() {
    super.initState();
    _recordedAt = DateTime.now();
    _selectedTopicId = widget.editingItem?.topicId ??
        widget.initialTopicId ??
        Defaults.defaultTopicId;
    _initFromEditing();
    _initFromScanDraft();
    _initFromCardContext();
    _montoController.addListener(_ensureMontoCursorAtEnd);
    _montoFocus.addListener(_onMontoFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRateForDate());
  }

  void _initFromCardContext() {
    if (widget.editingItem != null) return;
    final cardId = widget.initialCardId;
    if (cardId == null) return;
    _isIncome = false;
    _paymentMethod = widget.initialPaymentMethod ?? PaymentMethod.card;
    _selectedCardId = cardId;
  }

  void _onMontoFocusChange() {
    if (_montoFocus.hasFocus) {
      _pinMontoCursor();
    }
  }

  void _pinMontoCursor() {
    final text = _montoController.text;
    final end = TextSelection.collapsed(offset: text.length);
    if (_montoController.selection != end) {
      _montoController.selection = end;
    }
  }

  void _ensureMontoCursorAtEnd() {
    final text = _montoController.text;
    final sel = _montoController.selection;
    if (!sel.isValid) return;
    if (sel.baseOffset != text.length || sel.extentOffset != text.length) {
      _montoController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  bool _looksLikeConceptList(String value) {
    if (value.contains('\n')) return true;
    if (value.trimLeft().startsWith('•')) return true;
    return value.split(' · ').where((p) => p.trim().isNotEmpty).length >= 2;
  }

  String _stripConceptBullet(String line) {
    var text = line.trimLeft();
    if (text.startsWith('• ')) {
      text = text.substring(2);
    } else if (text.startsWith('•')) {
      text = text.substring(1).trimLeft();
    } else if (text.startsWith('- ')) {
      text = text.substring(2);
    }
    return text.trim();
  }

  String _conceptoForSave() {
    final raw = _conceptoController.text.trim();
    if (!_conceptoAsList) return raw;
    return raw
        .split(RegExp(r'\r?\n'))
        .map(_stripConceptBullet)
        .where((line) => line.isNotEmpty)
        .join(' · ');
  }

  void _setConceptoAsList(bool asList) {
    if (asList == _conceptoAsList) return;
    final current = _conceptoController.text;
    setState(() {
      if (asList) {
        final parts = current.contains('\n')
            ? current.split(RegExp(r'\r?\n'))
            : current.split(' · ');
        final items = parts
            .map(_stripConceptBullet)
            .where((p) => p.isNotEmpty)
            .toList();
        _conceptoController.text = items.isEmpty
            ? ConceptBulletListFormatter.bullet
            : items
                .map((p) => '${ConceptBulletListFormatter.bullet}$p')
                .join('\n');
        _conceptoAsList = true;
        _conceptoController.selection = TextSelection.collapsed(
          offset: _conceptoController.text.length,
        );
      } else {
        _conceptoController.text = current
            .split(RegExp(r'\r?\n'))
            .map(_stripConceptBullet)
            .where((line) => line.isNotEmpty)
            .join(' · ');
        _conceptoAsList = false;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_customRateController.text.isEmpty) {
      final customRate = ref.read(settingsProvider).settings.customRate;
      _customRateController.text = customRate.toStringAsFixed(2);
    }
  }

  Future<void> _refreshRateForDate() async {
    if (!mounted) return;
    final settings = ref.read(settingsProvider).settings;
    final requestId = ++_rateRequestId;

    if (_currency != 'bolivares') {
      setState(() {
        _rateForDate = null;
        _rateForDateLoading = false;
        _rateFromHistory = false;
      });
      return;
    }

    setState(() => _rateForDateLoading = true);

    final result = await ref.read(exchangeRateServiceProvider).fetchRateForDate(
          date: _effectiveDateTime,
          rateType: settings.rateType,
          customRate: settings.customRate,
          fallbackBcv: settings.lastRateBcv,
          fallbackParalelo: settings.lastRateParalelo,
        );

    if (!mounted || requestId != _rateRequestId) return;

    setState(() {
      _rateForDate = result?.promedio;
      _rateFromHistory = result?.fromHistory ?? false;
      _rateForDateLoading = false;
    });
  }

  double _rateForForm(double fallback) {
    if (_currency != 'bolivares') return fallback;
    final dateRate = _rateForDate;
    if (dateRate != null && dateRate > 0) return dateRate;
    return fallback;
  }

  void _initFromEditing() {
    final item = widget.editingItem;
    if (item == null) return;

    _conceptoController.text = item.title;
    _conceptoAsList = _looksLikeConceptList(item.title);
    if (_conceptoAsList) {
      final parts = item.title.contains('\n')
          ? item.title.split(RegExp(r'\r?\n'))
          : item.title.split(' · ');
      final items = parts
          .map(_stripConceptBullet)
          .where((p) => p.isNotEmpty)
          .toList();
      _conceptoController.text = items.isEmpty
          ? ConceptBulletListFormatter.bullet
          : items
              .map((p) => '${ConceptBulletListFormatter.bullet}$p')
              .join('\n');
    }
    final isBs = item.amount.contains('Bs');
    final numStr = item.amount.replaceAll(RegExp(r'[^0-9.,]'), '');
    _montoController.text =
        MoneyAmountInput.formatDouble(MoneyAmountInput.parse(numStr));
    _currency = isBs ? 'bolivares' : 'dollars';
    _isIncome = ActivityKind.isIncome(item.subtitle);
    _paymentMethod = PaymentMethod.resolve(
      paymentMethod: item.paymentMethod,
      cardId: item.cardId,
    );
    _selectedCardId = item.cardId;
  }

  void _initFromScanDraft() {
    if (widget.editingItem != null || widget.initialDraft == null) return;
    final draft = widget.initialDraft!;

    if (draft.monto != null && draft.monto! > 0) {
      _montoController.text = MoneyAmountInput.formatDouble(draft.monto!);
    }
    if (draft.currency != null) {
      _currency = draft.currency!;
    }
    if (draft.date != null) {
      _useCurrentDateTime = false;
      _recordedAt = draft.date!;
    }
    _isIncome = false;
    if (widget.initialPaymentMethod != null) {
      _paymentMethod = widget.initialPaymentMethod!;
      _selectedCardId = null;
    }
  }

  @override
  void dispose() {
    _montoController.removeListener(_ensureMontoCursorAtEnd);
    _montoFocus.removeListener(_onMontoFocusChange);
    _conceptoController.dispose();
    _montoController.dispose();
    _customRateController.dispose();
    _montoFocus.dispose();
    super.dispose();
  }

  DateTime get _effectiveDateTime =>
      _useCurrentDateTime ? DateTime.now() : _recordedAt;

  Future<void> _setRecordedAt(DateTime value) async {
    setState(() => _recordedAt = value);
    await _refreshRateForDate();
  }

  void _selectPaymentMethod(PaymentMethod method, {String? cardId}) {
    setState(() {
      _paymentMethod = method;
      _selectedCardId = method == PaymentMethod.card ? cardId : null;
      if (method == PaymentMethod.card && cardId != null) {
        PaymentCard? card;
        for (final c in ref.read(cardsProvider)) {
          if (c.id == cardId) {
            card = c;
            break;
          }
        }
        if (card != null && !card.currencyMode.supportsCurrency(_currency)) {
          _currency = card.currencyMode.preferredFormCurrency;
        }
      } else if (method == PaymentMethod.cashUsd) {
        _currency = 'dollars';
      } else if (method == PaymentMethod.cashVes ||
          method == PaymentMethod.pagoMovil) {
        _currency = 'bolivares';
      }
    });
    _refreshRateForDate();
  }

  void _setCurrency(String currency) {
    setState(() {
      _currency = currency;
      if (_paymentMethod == PaymentMethod.card && _selectedCardId != null) {
        PaymentCard? card;
        for (final c in ref.read(cardsProvider)) {
          if (c.id == _selectedCardId) {
            card = c;
            break;
          }
        }
        if (card != null && !card.currencyMode.supportsCurrency(currency)) {
          _selectedCardId = null;
          _paymentMethod = currency == 'dollars'
              ? PaymentMethod.cashUsd
              : PaymentMethod.pagoMovil;
        }
      }
    });
    _refreshRateForDate();
  }

  Future<void> _handleSave() async {
    final settings = ref.read(settingsProvider);
    final cards = ref.read(cardsProvider);
    final method = _paymentMethod;
    final cardId = method == PaymentMethod.card
        ? (_selectedCardId ?? (cards.isNotEmpty ? cards.first.id : null))
        : null;

    if (!_isIncome && method == PaymentMethod.card && cardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea una tarjeta o elige otro medio de pago')),
      );
      return;
    }

    if (!_isIncome && method == PaymentMethod.card && cardId != null) {
      PaymentCard? card;
      for (final c in cards) {
        if (c.id == cardId) {
          card = c;
          break;
        }
      }
      if (card != null && !card.currencyMode.supportsCurrency(_currency)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Esta tarjeta no maneja ${_currency == 'dollars' ? 'dólares' : 'bolívares'}',
            ),
          ),
        );
        return;
      }
    }

    final activity = ActivityBuilder.buildFromForm(
      id: widget.editingItem?.id,
      concepto: _conceptoForSave(),
      monto: _montoController.text.trim(),
      currency: _currency,
      isIncome: _isIncome,
      effectiveRate: _rateForForm(settings.effectiveRate),
      topicId: _selectedTopicId ?? Defaults.defaultTopicId,
      cardId: cardId,
      paymentMethod: method,
      date: _effectiveDateTime,
    );

    // Persistir siempre con el ref de esta pantalla (montada).
    // El onSave externo solo corre efectos secundarios (p. ej. cambiar de tab).
    try {
      if (widget.editingItem != null) {
        await ref.read(activitiesProvider.notifier).update(activity);
      } else {
        await ref.read(activitiesProvider.notifier).add(activity);
      }
    } catch (err, st) {
      debugPrint('RegisterTransactionScreen save failed: $err\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el movimiento')),
        );
      }
      return;
    }

    try {
      await widget.onSave(activity);
    } catch (err, st) {
      debugPrint('RegisterTransactionScreen onSave side-effect failed: $err\n$st');
    }

    if (mounted) Navigator.of(context).pop();
  }

  String get _title {
    if (widget.editingItem != null) return 'Editar movimiento';
    return _isIncome ? 'Nuevo ingreso' : 'Nuevo egreso';
  }

  String get _saveLabel {
    if (widget.editingItem != null) return 'Guardar cambios';
    return _isIncome ? 'Registrar ingreso' : 'Registrar egreso';
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.settings;
    final cards = ref.watch(cardsProvider);
    final topics = ref.watch(topicsProvider);
    final rate = _rateForForm(settingsState.effectiveRate);
    String? selectedTopicName = widget.topicName;
    if (_selectedTopicId != null) {
      for (final topic in topics) {
        if (topic.id == _selectedTopicId) {
          selectedTopicName = topic.name;
          break;
        }
      }
    } else {
      selectedTopicName = null;
    }
    final montoNum = MoneyAmountInput.parse(_montoController.text);
    final equivalenteEnBs = rate > 0 ? montoNum * rate : 0.0;
    final equivalenteEnUsd = rate > 0 ? montoNum / rate : 0.0;
    final cardSelected = _paymentMethod == PaymentMethod.card;
    final dateLabel = DateFormat('d MMM yyyy', 'es').format(_effectiveDateTime);
    final currencySymbol = _currency == 'bolivares' ? 'Bs' : '\$';

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (selectedTopicName != null)
                Text(
                  selectedTopicName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
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
                  _TypeSegment(
                    isIncome: _isIncome,
                    onChanged: (income) {
                      setState(() {
                        _isIncome = income;
                        if (income) {
                          _selectedCardId = null;
                          _paymentMethod = PaymentMethod.pagoMovil;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monto',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              currencySymbol,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: _montoController,
                                focusNode: _montoFocus,
                                keyboardType: TextInputType.number,
                                enableInteractiveSelection: false,
                                showCursor: true,
                                inputFormatters: const [
                                  MoneyAmountInputFormatter(),
                                ],
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -1,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0,00',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onTap: _pinMontoCursor,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        if (_currency == 'bolivares' && montoNum > 0 && rate > 0) ...[
                          const SizedBox(height: 12),
                          _HintRow(
                            icon: Icons.swap_horiz_rounded,
                            text:
                                '≈ ${equivalenteEnUsd.toStringAsFixed(2)} \$ · tasa ${rate.toStringAsFixed(2)} · $dateLabel',
                          ),
                        ] else if (_currency == 'dollars' && montoNum > 0 && rate > 0) ...[
                          const SizedBox(height: 12),
                          _HintRow(
                            icon: Icons.swap_horiz_rounded,
                            text:
                                '≈ ${CurrencyFormatter.formatBs(equivalenteEnBs)} · tasa ${rate.toStringAsFixed(2)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isIncome
                                  ? Icons.trending_up_outlined
                                  : Icons.receipt_long_outlined,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  'Concepto',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            _ConceptModeSwitch(
                              isList: _conceptoAsList,
                              onChanged: _setConceptoAsList,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _conceptoController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: _conceptoAsList
                              ? TextInputAction.newline
                              : TextInputAction.done,
                          keyboardType: _conceptoAsList
                              ? TextInputType.multiline
                              : TextInputType.text,
                          minLines: _conceptoAsList ? 3 : 1,
                          maxLines: _conceptoAsList ? null : 1,
                          inputFormatters: _conceptoAsList
                              ? const [ConceptBulletListFormatter()]
                              : const [],
                          decoration: InputDecoration(
                            hintText: _conceptoAsList
                                ? '• Ítem de la lista'
                                : (_isIncome
                                    ? 'Ej. Pago recibido'
                                    : 'Ej. Compra del día'),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    icon: Icons.payments_outlined,
                    title: 'Moneda',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _OptionTile(
                          selected: _currency == 'dollars',
                          label: 'Dólares',
                          subtitle: 'USD',
                          icon: Icons.attach_money,
                          onTap: () => _setCurrency('dollars'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OptionTile(
                          selected: _currency == 'bolivares',
                          label: 'Bolívares',
                          subtitle: 'VES',
                          icon: Icons.payments_outlined,
                          onTap: () => _setCurrency('bolivares'),
                        ),
                      ),
                    ],
                  ),
                  if (_currency == 'bolivares') ...[
                    const SizedBox(height: 12),
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Tasa de cambio',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: RateType.values.map((rt) {
                                final selected = settings.rateType == rt;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(rt.label),
                                    selected: selected,
                                    onSelected: (_) async {
                                      await ref.read(settingsProvider.notifier).setRateType(rt);
                                      await _refreshRateForDate();
                                    },
                                    selectedColor: AppColors.ink,
                                    labelStyle: TextStyle(
                                      color: selected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                    side: BorderSide(
                                      color: selected ? AppColors.ink : AppColors.border,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if (settings.rateType == RateType.personalizado) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('1 \$ = '),
                                Expanded(
                                  child: TextField(
                                    controller: _customRateController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(isDense: true),
                                    onChanged: (t) {
                                      final n = double.tryParse(t.replaceAll(',', '.'));
                                      if (n != null && n > 0) {
                                        ref.read(settingsProvider.notifier).setCustomRate(n);
                                        setState(() {
                                          _rateForDate = n;
                                          _rateFromHistory = false;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const Text(' Bs'),
                              ],
                            ),
                          ],
                          if (_rateForDateLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: LinearProgressIndicator(minHeight: 2),
                            )
                          else if (rate > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                '${settings.rateType.label}: ${rate.toStringAsFixed(2)} Bs/\$$dateLabel'
                                '${_rateFromHistory ? ' (histórico)' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (!_isIncome) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Medio de pago',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _PaymentChip(
                            label: PaymentMethod.pagoMovil.label,
                            selected: _paymentMethod == PaymentMethod.pagoMovil,
                            icon: Icons.phone_android_outlined,
                            onTap: () => _selectPaymentMethod(PaymentMethod.pagoMovil),
                          ),
                          const SizedBox(width: 8),
                          _PaymentChip(
                            label: PaymentMethod.cashUsd.label,
                            selected: _paymentMethod == PaymentMethod.cashUsd,
                            icon: Icons.attach_money,
                            onTap: () => _selectPaymentMethod(PaymentMethod.cashUsd),
                          ),
                          const SizedBox(width: 8),
                          _PaymentChip(
                            label: PaymentMethod.cashVes.label,
                            selected: _paymentMethod == PaymentMethod.cashVes,
                            icon: Icons.payments_outlined,
                            onTap: () => _selectPaymentMethod(PaymentMethod.cashVes),
                          ),
                          ...cards.map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _PaymentChip(
                                label:
                                    '${card.name} · ${card.currencyMode.shortLabel}',
                                selected:
                                    cardSelected && _selectedCardId == card.id,
                                icon: Icons.credit_card_outlined,
                                onTap: () => _selectPaymentMethod(
                                  PaymentMethod.card,
                                  cardId: card.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cards.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Para tarjeta, créala en la pestaña Tarjetas.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  _SectionHeader(
                    icon: Icons.sell_outlined,
                    title: 'Tópico',
                  ),
                  const SizedBox(height: 10),
                  _FormCard(
                    child: topics.isEmpty
                        ? const Text(
                            'No hay tópicos. Créalos en la pestaña Tópicos.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Asocia este movimiento a un tópico (opcional).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final topic in topics)
                                    _TopicChip(
                                      label: topic.name,
                                      selected: _selectedTopicId == topic.id,
                                      onTap: () => setState(
                                        () => _selectedTopicId = topic.id,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  if (widget.topicMode) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon: Icons.event_outlined,
                      title: 'Fecha y hora',
                    ),
                    const SizedBox(height: 10),
                    _FormCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _useCurrentDateTime,
                            onChanged: (v) async {
                              setState(() {
                                _useCurrentDateTime = v;
                                if (_useCurrentDateTime) {
                                  _recordedAt = DateTime.now();
                                }
                              });
                              await _refreshRateForDate();
                            },
                            title: const Text(
                              'Usar ahora',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              _useCurrentDateTime
                                  ? 'Se guardará con la hora actual'
                                  : 'Elige fecha y hora abajo',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          if (!_useCurrentDateTime) ...[
                            const SizedBox(height: 14),
                            _ManualDateTimePicker(
                              dateTime: _recordedAt,
                              onChanged: _setRecordedAt,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: FilledButton(
                key: TutorialKeys.registerSaveButton,
                onPressed: _handleSave,
                child: Text(_saveLabel),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Material propio para que ListTile/SwitchListTile pinten ink
    // sobre este ancestro y no queden tapados por un DecoratedBox.
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _ManualDateTimePicker extends StatefulWidget {
  const _ManualDateTimePicker({
    required this.dateTime,
    required this.onChanged,
  });

  final DateTime dateTime;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_ManualDateTimePicker> createState() => _ManualDateTimePickerState();
}

class _ManualDateTimePickerState extends State<_ManualDateTimePicker> {
  OverlayEntry? _overlayEntry;
  _DateTimePopupKind? _openKind;

  static String _friendlyDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff == -1) return 'Mañana';
    if (diff > 1 && diff < 7) {
      return DateFormat('EEEE', 'es').format(dt);
    }
    if (dt.year == now.year) {
      return DateFormat('d MMM', 'es').format(dt);
    }
    return DateFormat('d MMM yyyy', 'es').format(dt);
  }

  static String _dateDetail(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays.abs();

    if (diff < 7) {
      if (dt.year == now.year) {
        return DateFormat("d 'de' MMMM", 'es').format(dt);
      }
      return DateFormat('d MMM yyyy', 'es').format(dt);
    }
    return DateFormat('EEEE', 'es').format(dt);
  }

  static String _friendlyTime(DateTime dt) {
    return DateFormat('h:mm a', 'es').format(dt).toLowerCase();
  }

  static String _timePeriod(DateTime dt) {
    final h = dt.hour;
    if (h < 12) return 'Antes del mediodía';
    if (h < 18) return 'Por la tarde';
    return 'Por la noche';
  }

  static String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  void _toggle(_DateTimePopupKind kind) {
    if (_openKind == kind) {
      _closePopup();
    } else {
      _openPopup(kind);
    }
  }

  void _openPopup(_DateTimePopupKind kind) {
    _closePopup();
    final overlay = Overlay.of(context);
    final maxWidth = kind == _DateTimePopupKind.date ? 320.0 : 260.0;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePopup,
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kind == _DateTimePopupKind.date
                          ? _DatePopupContent(
                              initial: widget.dateTime,
                              onSelected: (date) {
                                widget.onChanged(
                                  DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    widget.dateTime.hour,
                                    widget.dateTime.minute,
                                  ),
                                );
                                _closePopup();
                              },
                            )
                          : _TimePopupContent(
                              initial: widget.dateTime,
                              onSelected: (time) {
                                widget.onChanged(
                                  DateTime(
                                    widget.dateTime.year,
                                    widget.dateTime.month,
                                    widget.dateTime.day,
                                    time.hour,
                                    time.minute,
                                  ),
                                );
                                _closePopup();
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_overlayEntry!);
    setState(() => _openKind = kind);
  }

  void _closePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_openKind != null) {
      setState(() => _openKind = null);
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateTimeChoiceCard(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: _capitalize(_friendlyDate(widget.dateTime)),
            detail: _capitalize(_dateDetail(widget.dateTime)),
            selected: _openKind == _DateTimePopupKind.date,
            onTap: () => _toggle(_DateTimePopupKind.date),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DateTimeChoiceCard(
            icon: Icons.schedule_outlined,
            label: 'Hora',
            value: _friendlyTime(widget.dateTime),
            detail: _timePeriod(widget.dateTime),
            selected: _openKind == _DateTimePopupKind.time,
            onTap: () => _toggle(_DateTimePopupKind.time),
          ),
        ),
      ],
    );
  }
}

enum _DateTimePopupKind { date, time }

class _DatePopupContent extends StatelessWidget {
  const _DatePopupContent({
    required this.initial,
    required this.onSelected,
  });

  final DateTime initial;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: CalendarDatePicker(
        initialDate: initial,
        currentDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        onDateChanged: onSelected,
      ),
    );
  }
}

class _TimePopupContent extends StatefulWidget {
  const _TimePopupContent({
    required this.initial,
    required this.onSelected,
  });

  final DateTime initial;
  final ValueChanged<TimeOfDay> onSelected;

  @override
  State<_TimePopupContent> createState() => _TimePopupContentState();
}

class _TimePopupContentState extends State<_TimePopupContent> {
  late int _hour12;
  late int _minute;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    final tod = TimeOfDay.fromDateTime(widget.initial);
    _isPm = tod.period == DayPeriod.pm;
    _hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    _minute = tod.minute;
  }

  TimeOfDay get _current {
    var hour = _hour12 % 12;
    if (_isPm) hour += 12;
    return TimeOfDay(hour: hour, minute: _minute);
  }

  void _apply() => widget.onSelected(_current);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Elige la hora',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeWheelColumn(
                value: _hour12,
                values: List.generate(12, (i) => i + 1),
                labelBuilder: (v) => '$v',
                onChanged: (v) => setState(() => _hour12 = v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _TimeWheelColumn(
                value: _minute,
                values: List.generate(60, (i) => i),
                labelBuilder: (v) => v.toString().padLeft(2, '0'),
                onChanged: (v) => setState(() => _minute = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.softFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _AmpmChip(
                    label: 'a. m.',
                    selected: !_isPm,
                    onTap: () => setState(() => _isPm = false),
                  ),
                ),
                Expanded(
                  child: _AmpmChip(
                    label: 'p. m.',
                    selected: _isPm,
                    onTap: () => setState(() => _isPm = true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Listo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeWheelColumn extends StatefulWidget {
  const _TimeWheelColumn({
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final int value;
  final List<int> values;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onChanged;

  @override
  State<_TimeWheelColumn> createState() => _TimeWheelColumnState();
}

class _TimeWheelColumnState extends State<_TimeWheelColumn> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    final initialIndex =
        widget.values.indexOf(widget.value).clamp(0, widget.values.length - 1);
    _controller = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 64,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        diameterRatio: 1.3,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        controller: _controller,
        onSelectedItemChanged: (index) => widget.onChanged(widget.values[index]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.values.length,
          builder: (context, index) {
            final selected = widget.values[index] == widget.value;
            return Center(
              child: Text(
                widget.labelBuilder(widget.values[index]),
                style: TextStyle(
                  fontSize: selected ? 26 : 18,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? AppColors.ink : AppColors.textMuted,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AmpmChip extends StatelessWidget {
  const _AmpmChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.ink : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeChoiceCard extends StatelessWidget {
  const _DateTimeChoiceCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.softFillDark : AppColors.softFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConceptModeSwitch extends StatelessWidget {
  const _ConceptModeSwitch({
    required this.isList,
    required this.onChanged,
  });

  final bool isList;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const width = 118.0;
    const height = 30.0;
    const padding = 2.0;
    final thumbWidth = (width - padding * 2) / 2;

    return GestureDetector(
      onTap: () => onChanged(!isList),
      child: Semantics(
        button: true,
        toggled: isList,
        label: isList ? 'Modo lista' : 'Modo texto',
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppColors.softFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment:
                    isList ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: thumbWidth,
                  height: height - padding * 2,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isList
                              ? AppColors.textSecondary
                              : Colors.white,
                        ),
                        child: const Text('texto'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isList
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        child: const Text('lista'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En modo lista, cada Enter abre una línea nueva con `• ` al inicio.
class ConceptBulletListFormatter extends TextInputFormatter {
  const ConceptBulletListFormatter();

  static const bullet = '• ';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = newValue.selection.baseOffset;

    if (text.isEmpty) {
      return const TextEditingValue(
        text: bullet,
        selection: TextSelection.collapsed(offset: bullet.length),
      );
    }

    // Enter: se insertó un salto de línea → viñeta en la nueva línea.
    final enterAt = _detectInsertedNewline(oldValue.text, text, cursor);
    if (enterAt != null) {
      text =
          '${text.substring(0, enterAt + 1)}$bullet${text.substring(enterAt + 1)}';
      cursor = enterAt + 1 + bullet.length;
    }

    final lines = text.split('\n');
    final rebuilt = <String>[];
    for (final line in lines) {
      if (line.startsWith(bullet)) {
        rebuilt.add(line);
      } else if (line.startsWith('•')) {
        rebuilt.add('$bullet${line.substring(1).trimLeft()}');
      } else {
        rebuilt.add('$bullet$line');
      }
    }
    final formatted = rebuilt.join('\n');

    // Si solo cambiamos por Enter, el cursor ya apunta tras la viñeta.
    if (enterAt != null) {
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: cursor.clamp(0, formatted.length),
        ),
      );
    }

    // Mantener el cursor relativo al final si el prefijo creció en la 1ª línea.
    final delta = formatted.length - text.length;
    final safeCursor = (cursor + delta).clamp(0, formatted.length);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: safeCursor),
    );
  }

  int? _detectInsertedNewline(String oldText, String newText, int cursor) {
    if (newText.length < oldText.length + 1) return null;
    if (cursor > 0 &&
        cursor <= newText.length &&
        newText[cursor - 1] == '\n' &&
        newText.length == oldText.length + 1) {
      return cursor - 1;
    }

    final oldCount = '\n'.allMatches(oldText).length;
    final newCount = '\n'.allMatches(newText).length;
    if (newCount != oldCount + 1) return null;

    for (var i = 0; i < newText.length; i++) {
      if (newText[i] != '\n') continue;
      final candidate = newText.substring(0, i) + newText.substring(i + 1);
      if (candidate == oldText) return i;
    }
    return null;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment({required this.isIncome, required this.onChanged});

  final bool isIncome;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.softFillDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              selected: !isIncome,
              label: 'Egreso',
              icon: Icons.north_east_rounded,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              selected: isIncome,
              label: 'Ingreso',
              icon: Icons.south_west_rounded,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.ink : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.ink : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.softFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
