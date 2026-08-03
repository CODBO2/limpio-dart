import '../../models/activity.dart';
import '../../models/activity_builder.dart';
import '../../models/fuente.dart';
import '../constants/defaults.dart';

class AmountParser {
  static double parseAmountToUsd(String amountStr, {double rate = Defaults.defaultBsToUsdRate}) {
    if (amountStr.isEmpty) return 0;
    final trimmed = amountStr.trim();
    final isBs = RegExp(r'Bs$', caseSensitive: false).hasMatch(trimmed);
    final numStr = trimmed
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s*\$\s*$'), '')
        .replaceAll(RegExp(r'\s*Bs\s*$', caseSensitive: false), '')
        .trim();
    final num = double.tryParse(numStr) ?? 0;
    return isBs ? num / rate : num;
  }

  static double fuenteAmountToUsd(Fuente fuente, {double rate = Defaults.defaultBsToUsdRate}) {
    final num = double.tryParse(fuente.amount.replaceAll(',', '')) ?? 0;
    return fuente.currency == 'VES' ? num / rate : num;
  }
}

class BalanceCalculator {
  static BalanceTotals computeTotals(
    List<Activity> activities, {
    double rate = Defaults.defaultBsToUsdRate,
  }) {
    final totalIncome = activities
        .where((a) => ActivityKind.isIncome(a.subtitle))
        .fold<double>(0, (sum, a) => sum + AmountParser.parseAmountToUsd(a.amount, rate: rate));

    final totalExpenses = activities
        .where((a) => !ActivityKind.isIncome(a.subtitle))
        .fold<double>(0, (sum, a) => sum + AmountParser.parseAmountToUsd(a.amount, rate: rate));

    return BalanceTotals(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: totalIncome - totalExpenses,
    );
  }
}

class BalanceTotals {
  const BalanceTotals({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  final double totalIncome;
  final double totalExpenses;
  final double balance;
}

class TopicExtremes {
  const TopicExtremes({this.largest});

  /// Single peak movement for the topic (expense or income), never both.
  final Activity? largest;

  bool get hasAny => largest != null;

  bool get isIncome =>
      largest != null && ActivityKind.isIncome(largest!.subtitle);

  String get label => isIncome ? 'Ingreso mayor' : 'Egreso mayor';

  static double amountUsd(Activity activity, {required double rate}) {
    return activity.equivalentUsd ??
        AmountParser.parseAmountToUsd(activity.amount, rate: rate);
  }

  static TopicExtremes fromActivities(
    List<Activity> activities, {
    required double rate,
  }) {
    Activity? largest;
    var largestUsd = -1.0;

    for (final activity in activities) {
      final usd = amountUsd(activity, rate: rate);
      if (usd > largestUsd) {
        largestUsd = usd;
        largest = activity;
      }
    }

    return TopicExtremes(largest: largest);
  }
}

double getEffectiveRate({
  required String rateType,
  required double customRate,
  required double rateBcv,
  required double rateParalelo,
}) {
  switch (rateType) {
    case 'bcv':
      return rateBcv > 0 ? rateBcv : Defaults.rateBcvFallback;
    case 'personalizado':
      return customRate > 0 ? customRate : Defaults.defaultBsToUsdRate;
    default:
      return rateParalelo > 0 ? rateParalelo : Defaults.rateParaleloFallback;
  }
}
