import '../../models/activity.dart';
import '../../models/activity_builder.dart';
import '../constants/defaults.dart';
import 'amount_parser.dart';

class WeeklyExpenseDay {
  const WeeklyExpenseDay({
    required this.label,
    required this.date,
    required this.amountUsd,
  });

  final String label;
  final DateTime date;
  final double amountUsd;
}

class WeeklyExpenseStats {
  const WeeklyExpenseStats({
    required this.days,
    required this.weekStart,
    required this.weekEnd,
    required this.totalUsd,
  });

  final List<WeeklyExpenseDay> days;
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalUsd;

  double get maxAmount {
    var max = 0.0;
    for (final day in days) {
      if (day.amountUsd > max) max = day.amountUsd;
    }
    return max;
  }
}

class WeeklyExpenseCalculator {
  static const weekdayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  static const _monthMap = <String, int>{
    'ene': 1,
    'enero': 1,
    'feb': 2,
    'febrero': 2,
    'mar': 3,
    'marzo': 3,
    'abr': 4,
    'abril': 4,
    'may': 5,
    'mayo': 5,
    'jun': 6,
    'junio': 6,
    'jul': 7,
    'julio': 7,
    'ago': 8,
    'agosto': 8,
    'sep': 9,
    'sept': 9,
    'septiembre': 9,
    'set': 9,
    'oct': 10,
    'octubre': 10,
    'nov': 11,
    'noviembre': 11,
    'dic': 12,
    'diciembre': 12,
  };

  /// Normaliza a medianoche (día calendario).
  static DateTime dayOnly(DateTime reference) =>
      DateTime(reference.year, reference.month, reference.day);

  /// Monday of the week that contains [reference].
  static DateTime weekStartOf(DateTime reference) {
    final day = dayOnly(reference);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// Etiqueta corta del día de la semana (Lun…Dom).
  static String weekdayLabel(DateTime date) =>
      weekdayLabels[date.weekday - DateTime.monday];

  /// Computa gastos de 7 días a partir de [weekStart] (día inclusive).
  /// Si se omite, usa hoy + [weekOffset] semanas.
  static WeeklyExpenseStats compute(
    List<Activity> activities, {
    DateTime? weekStart,
    DateTime? reference,
    int weekOffset = 0,
    double rate = Defaults.defaultBsToUsdRate,
  }) {
    final now = reference ?? DateTime.now();
    final start = weekStart != null
        ? dayOnly(weekStart)
        : dayOnly(now).add(Duration(days: 7 * weekOffset));
    final weekEnd = start.add(const Duration(days: 6));

    final totals = List<double>.filled(7, 0);

    for (final activity in activities) {
      if (ActivityKind.isIncome(activity.subtitle)) continue;
      final date = parseActivityDate(activity.date, fallbackYear: now.year);
      if (date == null) continue;

      final day = dayOnly(date);
      if (day.isBefore(start) || day.isAfter(weekEnd)) continue;

      final index = day.difference(start).inDays;
      if (index < 0 || index > 6) continue;

      totals[index] += AmountParser.parseAmountToUsd(activity.amount, rate: rate);
    }

    final days = <WeeklyExpenseDay>[];
    var totalUsd = 0.0;
    for (var i = 0; i < 7; i++) {
      final amount = totals[i];
      totalUsd += amount;
      final date = start.add(Duration(days: i));
      days.add(
        WeeklyExpenseDay(
          label: weekdayLabel(date),
          date: date,
          amountUsd: amount,
        ),
      );
    }

    return WeeklyExpenseStats(
      days: days,
      weekStart: start,
      weekEnd: weekEnd,
      totalUsd: totalUsd,
    );
  }

  static DateTime? parseActivityDate(String raw, {required int fallbackYear}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase().startsWith('día')) return null;

    final slash = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(trimmed);
    if (slash != null) {
      final day = int.parse(slash.group(1)!);
      final month = int.parse(slash.group(2)!);
      var year = int.parse(slash.group(3)!);
      if (year < 100) year += 2000;
      return DateTime(year, month, day);
    }

    final match = RegExp(
      r'^(\d{1,2})\s+([A-Za-záéíóúñÁÉÍÓÚÑ\.]+)',
      unicode: true,
    ).firstMatch(trimmed);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final monthKey = match
        .group(2)!
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    final month = _monthMap[monthKey];
    if (day == null || month == null) return null;

    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(trimmed);
    final year = yearMatch != null ? int.parse(yearMatch.group(1)!) : fallbackYear;

    return DateTime(year, month, day);
  }
}
