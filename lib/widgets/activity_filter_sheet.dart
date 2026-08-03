import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/weekly_expense_calculator.dart';
import '../models/activity.dart';
import '../models/activity_builder.dart';
import '../models/payment_card.dart';
import '../models/payment_method.dart';
import 'week_range_picker.dart';

enum ActivityDatePeriod {
  all,
  today,
  last7Days,
  thisMonth,
  custom,
}

class ActivityFilterState {
  const ActivityFilterState({
    this.typeFilter = allType,
    this.paymentFilter,
    this.datePeriod = ActivityDatePeriod.all,
    this.customDateFrom,
    this.customDateTo,
  });

  static const allType = 'all';
  static const incomeType = 'ingreso';
  static const expenseType = 'gasto';
  static const anyCard = 'card';

  final String typeFilter;
  final String? paymentFilter;
  final ActivityDatePeriod datePeriod;
  final DateTime? customDateFrom;
  final DateTime? customDateTo;

  bool get isActive =>
      typeFilter != allType ||
      paymentFilter != null ||
      datePeriod != ActivityDatePeriod.all;

  ActivityFilterState copyWith({
    String? typeFilter,
    String? paymentFilter,
    bool clearPaymentFilter = false,
    ActivityDatePeriod? datePeriod,
    DateTime? customDateFrom,
    DateTime? customDateTo,
    bool clearCustomDates = false,
  }) {
    return ActivityFilterState(
      typeFilter: typeFilter ?? this.typeFilter,
      paymentFilter:
          clearPaymentFilter ? null : (paymentFilter ?? this.paymentFilter),
      datePeriod: datePeriod ?? this.datePeriod,
      customDateFrom: clearCustomDates
          ? null
          : (customDateFrom ?? this.customDateFrom),
      customDateTo:
          clearCustomDates ? null : (customDateTo ?? this.customDateTo),
    );
  }

  static String forCard(String cardId) => 'card:$cardId';

  static String? cardIdFromFilter(String filter) {
    if (filter.startsWith('card:') && filter.length > 5) {
      return filter.substring(5);
    }
    return null;
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Inclusive day range for the active date filter, or `(null, null)` if none.
  (DateTime?, DateTime?) resolveDateRange({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = _dayOnly(reference);

    switch (datePeriod) {
      case ActivityDatePeriod.all:
        return (null, null);
      case ActivityDatePeriod.today:
        return (today, today);
      case ActivityDatePeriod.last7Days:
        return (today.subtract(const Duration(days: 6)), today);
      case ActivityDatePeriod.thisMonth:
        return (DateTime(today.year, today.month, 1), today);
      case ActivityDatePeriod.custom:
        final from =
            customDateFrom != null ? _dayOnly(customDateFrom!) : null;
        final to = customDateTo != null ? _dayOnly(customDateTo!) : null;
        return (from, to);
    }
  }

  static bool matchesType(String typeFilter, String subtitle) {
    if (typeFilter == allType) return true;
    final income = ActivityKind.isIncome(subtitle);
    if (typeFilter == incomeType) return income;
    if (typeFilter == expenseType) return !income;
    return true;
  }

  static bool matchesPayment(Activity activity, String? paymentFilter) {
    if (paymentFilter == null) return true;

    final method = PaymentMethod.resolve(
      paymentMethod: activity.paymentMethod,
      cardId: activity.cardId,
    );

    if (paymentFilter == anyCard) {
      return method == PaymentMethod.card;
    }

    final specificCardId = cardIdFromFilter(paymentFilter);
    if (specificCardId != null) {
      return method == PaymentMethod.card && activity.cardId == specificCardId;
    }

    return method.value == paymentFilter;
  }

  bool matchesDate(Activity activity, {DateTime? now}) {
    final (from, to) = resolveDateRange(now: now);
    if (from == null && to == null) return true;

    final reference = now ?? DateTime.now();
    final parsed = WeeklyExpenseCalculator.parseActivityDate(
      activity.date,
      fallbackYear: reference.year,
    );
    if (parsed == null) return false;

    final day = _dayOnly(parsed);
    if (from != null && day.isBefore(from)) return false;
    if (to != null && day.isAfter(to)) return false;
    return true;
  }

  bool matches(Activity activity) {
    return matchesType(typeFilter, activity.subtitle) &&
        matchesPayment(activity, paymentFilter) &&
        matchesDate(activity);
  }

  String summaryLabel(List<PaymentCard> cards) {
    final parts = <String>[];

    if (typeFilter == incomeType) {
      parts.add('Ingresos');
    } else if (typeFilter == expenseType) {
      parts.add('Egresos');
    }

    if (paymentFilter != null) {
      parts.add(_paymentLabel(paymentFilter!, cards));
    }

    final dateLabel = _dateSummaryLabel();
    if (dateLabel != null) parts.add(dateLabel);

    if (parts.isEmpty) return 'Sin filtros';
    return parts.join(' · ');
  }

  String? _dateSummaryLabel() {
    switch (datePeriod) {
      case ActivityDatePeriod.all:
        return null;
      case ActivityDatePeriod.today:
        return 'Hoy';
      case ActivityDatePeriod.last7Days:
        return 'Últimos 7 días';
      case ActivityDatePeriod.thisMonth:
        return 'Este mes';
      case ActivityDatePeriod.custom:
        final (from, to) = resolveDateRange();
        if (from == null || to == null) return 'Rango';
        final fmt = DateFormat('d MMM', 'es');
        if (from.year == to.year &&
            from.month == to.month &&
            from.day == to.day) {
          return fmt.format(from);
        }
        return '${fmt.format(from)} – ${fmt.format(to)}';
    }
  }

  static String _paymentLabel(String filter, List<PaymentCard> cards) {
    if (filter == anyCard) return 'Cualquier tarjeta';

    final cardId = cardIdFromFilter(filter);
    if (cardId != null) {
      for (final card in cards) {
        if (card.id == cardId) return card.displayLabel;
      }
      return 'Tarjeta';
    }

    return PaymentMethod.fromString(filter).label;
  }
}

Future<ActivityFilterState?> showActivityFilterSheet(
  BuildContext context, {
  required ActivityFilterState current,
  required List<PaymentCard> cards,
  List<Activity> activities = const [],
}) {
  return showModalBottomSheet<ActivityFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ActivityFilterSheet(
      current: current,
      cards: cards,
      activities: activities,
    ),
  );
}

class _ActivityFilterSheet extends StatefulWidget {
  const _ActivityFilterSheet({
    required this.current,
    required this.cards,
    this.activities = const [],
  });

  final ActivityFilterState current;
  final List<PaymentCard> cards;
  final List<Activity> activities;

  @override
  State<_ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<_ActivityFilterSheet> {
  late String _typeFilter = widget.current.typeFilter;
  late String? _paymentFilter = widget.current.paymentFilter;
  late ActivityDatePeriod _datePeriod = widget.current.datePeriod;
  late DateTime? _customDateFrom = widget.current.customDateFrom;
  late DateTime? _customDateTo = widget.current.customDateTo;

  bool get _canReset =>
      _typeFilter != ActivityFilterState.allType ||
      _paymentFilter != null ||
      _datePeriod != ActivityDatePeriod.all;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialStart =
        _customDateFrom ?? today.subtract(const Duration(days: 6));
    final initialEnd = _customDateTo ?? today;

    final range = await showAppDateRangePicker(
      context,
      firstDate: DateTime(2018, 1, 1),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(today) ? today : initialStart,
        end: initialEnd.isAfter(today) ? today : initialEnd,
      ),
      activities: widget.activities,
    );

    if (range == null || !mounted) return;
    setState(() {
      _datePeriod = ActivityDatePeriod.custom;
      _customDateFrom =
          DateTime(range.start.year, range.start.month, range.start.day);
      _customDateTo =
          DateTime(range.end.year, range.end.month, range.end.day);
    });
  }

  String get _customRangeLabel {
    if (_customDateFrom == null || _customDateTo == null) {
      return 'Rango personalizado';
    }
    final fmt = DateFormat('d MMM', 'es');
    final from = _customDateFrom!;
    final to = _customDateTo!;
    if (from.year == to.year && from.month == to.month && from.day == to.day) {
      return fmt.format(from);
    }
    return '${fmt.format(from)} – ${fmt.format(to)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filtro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige tipo, medio de pago y fecha.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle('TIPO'),
                    const SizedBox(height: 8),
                    _FilterOptionTile(
                      icon: Icons.layers_outlined,
                      label: 'Todos',
                      selected: _typeFilter == ActivityFilterState.allType,
                      onTap: () => setState(
                        () => _typeFilter = ActivityFilterState.allType,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.trending_up,
                      label: 'Ingresos',
                      selected: _typeFilter == ActivityFilterState.incomeType,
                      onTap: () => setState(
                        () => _typeFilter = ActivityFilterState.incomeType,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.north_east_rounded,
                      label: 'Egresos',
                      selected: _typeFilter == ActivityFilterState.expenseType,
                      onTap: () => setState(
                        () => _typeFilter = ActivityFilterState.expenseType,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _SectionTitle('FECHA'),
                    const SizedBox(height: 8),
                    _FilterOptionTile(
                      icon: Icons.all_inclusive,
                      label: 'Todas las fechas',
                      selected: _datePeriod == ActivityDatePeriod.all,
                      onTap: () => setState(
                        () => _datePeriod = ActivityDatePeriod.all,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.today_outlined,
                      label: 'Hoy',
                      selected: _datePeriod == ActivityDatePeriod.today,
                      onTap: () => setState(
                        () => _datePeriod = ActivityDatePeriod.today,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.date_range_outlined,
                      label: 'Últimos 7 días',
                      selected: _datePeriod == ActivityDatePeriod.last7Days,
                      onTap: () => setState(
                        () => _datePeriod = ActivityDatePeriod.last7Days,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Este mes',
                      selected: _datePeriod == ActivityDatePeriod.thisMonth,
                      onTap: () => setState(
                        () => _datePeriod = ActivityDatePeriod.thisMonth,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.edit_calendar_outlined,
                      label: _customRangeLabel,
                      selected: _datePeriod == ActivityDatePeriod.custom,
                      onTap: _pickCustomRange,
                    ),
                    const SizedBox(height: 8),
                    const _SectionTitle('MEDIO DE PAGO'),
                    const SizedBox(height: 8),
                    _FilterOptionTile(
                      icon: Icons.all_inclusive,
                      label: 'Todos los medios',
                      selected: _paymentFilter == null,
                      onTap: () => setState(() => _paymentFilter = null),
                    ),
                    _FilterOptionTile(
                      icon: Icons.phone_android_outlined,
                      label: PaymentMethod.pagoMovil.label,
                      selected: _paymentFilter == PaymentMethod.pagoMovil.value,
                      onTap: () => setState(
                        () => _paymentFilter = PaymentMethod.pagoMovil.value,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.attach_money,
                      label: PaymentMethod.cashUsd.label,
                      selected: _paymentFilter == PaymentMethod.cashUsd.value,
                      onTap: () => setState(
                        () => _paymentFilter = PaymentMethod.cashUsd.value,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.payments_outlined,
                      label: PaymentMethod.cashVes.label,
                      selected: _paymentFilter == PaymentMethod.cashVes.value,
                      onTap: () => setState(
                        () => _paymentFilter = PaymentMethod.cashVes.value,
                      ),
                    ),
                    _FilterOptionTile(
                      icon: Icons.credit_card,
                      label: 'Cualquier tarjeta',
                      selected: _paymentFilter == ActivityFilterState.anyCard,
                      onTap: () => setState(
                        () => _paymentFilter = ActivityFilterState.anyCard,
                      ),
                    ),
                    if (widget.cards.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                        child: Text(
                          'TARJETAS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      ...widget.cards.map((card) {
                        final id = ActivityFilterState.forCard(card.id);
                        return _FilterOptionTile(
                          icon: Icons.credit_card_outlined,
                          label: card.displayLabel,
                          selected: _paymentFilter == id,
                          onTap: () => setState(() => _paymentFilter = id),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _canReset
                        ? () => Navigator.pop(
                              context,
                              const ActivityFilterState(),
                            )
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: _canReset
                            ? AppColors.borderStrong
                            : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Restablecer'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      ActivityFilterState(
                        typeFilter: _typeFilter,
                        paymentFilter: _paymentFilter,
                        datePeriod: _datePeriod,
                        customDateFrom: _customDateFrom,
                        customDateTo: _customDateTo,
                      ),
                    ),
                    child: const Text('Aplicar'),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.softFillDark : AppColors.softFill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
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
                  color: selected ? AppColors.ink : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, size: 20, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
