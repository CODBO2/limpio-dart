import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/weekly_expense_calculator.dart';
import '../models/activity.dart';
import '../providers/settings_provider.dart';
import 'week_range_picker.dart';

class WeeklyExpenseChart extends ConsumerStatefulWidget {
  const WeeklyExpenseChart({
    super.key,
    required this.activities,
    required this.rate,
  });

  final List<Activity> activities;
  final double rate;

  @override
  ConsumerState<WeeklyExpenseChart> createState() => _WeeklyExpenseChartState();
}

class _WeeklyExpenseChartState extends ConsumerState<WeeklyExpenseChart> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(settingsProvider).settings.weeklyExpenseWeekStart;
    _weekStart = WeeklyExpenseCalculator.dayOnly(saved ?? DateTime.now());
  }

  WeeklyExpenseStats get _stats => WeeklyExpenseCalculator.compute(
        widget.activities,
        weekStart: _weekStart,
        rate: widget.rate,
      );

  bool get _isStartingToday =>
      _isSameDay(_weekStart, WeeklyExpenseCalculator.dayOnly(DateTime.now()));

  void _onWeekConfirmed(DateTime weekStart) {
    final day = WeeklyExpenseCalculator.dayOnly(weekStart);
    setState(() {
      _weekStart = day;
    });
    ref.read(settingsProvider.notifier).setWeeklyExpenseWeekStart(day);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final maxAmount = stats.maxAmount <= 0 ? 1.0 : stats.maxAmount;
    final rangeLabel =
        '${DateFormat('d MMM', 'es').format(stats.weekStart)} – ${DateFormat('d MMM', 'es').format(stats.weekEnd)}';
    final selectorLabel = _isStartingToday ? 'Desde hoy' : rangeLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'GASTO SEMANAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              Expanded(
                child: Center(
                  child: _WeekSelectorButton(
                    label: selectorLabel,
                    weekStart: _weekStart,
                    activities: widget.activities,
                    onWeekConfirmed: _onWeekConfirmed,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.formatUsd(stats.totalUsd),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final day in stats.days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _BarColumn(
                        label: day.label,
                        amount: day.amountUsd,
                        maxAmount: maxAmount,
                        isToday: _isSameDay(day.date, DateTime.now()),
                        isMax: day.amountUsd > 0 &&
                            day.amountUsd == stats.maxAmount,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _WeekSelectorButton extends StatefulWidget {
  const _WeekSelectorButton({
    required this.label,
    required this.weekStart,
    required this.activities,
    required this.onWeekConfirmed,
  });

  final String label;
  final DateTime weekStart;
  final List<Activity> activities;
  final ValueChanged<DateTime> onWeekConfirmed;

  @override
  State<_WeekSelectorButton> createState() => _WeekSelectorButtonState();
}

class _WeekSelectorButtonState extends State<_WeekSelectorButton> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _togglePopup() {
    if (_overlayEntry != null) {
      _closePopup();
    } else {
      _openPopup();
    }
  }

  void _openPopup() {
    _overlayEntry = insertWeekRangePickerOverlay(
      context: context,
      link: _layerLink,
      initialWeekStart: widget.weekStart,
      activities: widget.activities,
      onConfirm: widget.onWeekConfirmed,
      onDismiss: _closePopup,
    );
    setState(() => _isOpen = true);
  }

  void _closePopup() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    entry?.remove();
    if (_isOpen) {
      setState(() => _isOpen = false);
    }
  }

  @override
  void dispose() {
    _closePopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: _togglePopup,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  _isOpen
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.isToday,
    required this.isMax,
  });

  static const _orangeStrong = Color(0xFFE67E22);
  static const _orangeWeak = Color(0xFFFCE8CC);
  static const _orangeLabelStrong = Color(0xFFD35400);
  static const _orangeLabelWeak = Color(0xFFE8A54A);

  final String label;
  final double amount;
  final double maxAmount;
  final bool isToday;
  final bool isMax;

  @override
  Widget build(BuildContext context) {
    final hasExpense = amount > 0;
    final ratio = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;

    final barColor = hasExpense
        ? Color.lerp(_orangeWeak, _orangeStrong, ratio)!
        : AppColors.softFillDark;

    final labelColor = hasExpense
        ? Color.lerp(_orangeLabelWeak, _orangeLabelStrong, ratio)!
        : isToday
            ? AppColors.ink
            : AppColors.textMuted;

    final labelWeight = isMax || isToday
        ? FontWeight.w800
        : hasExpense
            ? FontWeight.w700
            : FontWeight.w600;

    return Column(
      children: [
        SizedBox(
          height: 18,
          child: hasExpense
              ? Text(
                  amount >= 100
                      ? amount.toStringAsFixed(0)
                      : amount.toStringAsFixed(1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: hasExpense ? (0.12 + ratio * 0.88) : 0.04,
              widthFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 16,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: labelWeight,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
  }
}
