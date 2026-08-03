import '../core/constants/defaults.dart';
import 'rate_type.dart';

class AppSettings {
  const AppSettings({
    this.rateType = RateType.paralelo,
    this.customRate = Defaults.defaultBsToUsdRate,
    this.warningLimit,
    this.lastRateBcv = Defaults.rateBcvFallback,
    this.lastRateParalelo = Defaults.rateParaleloFallback,
    this.isOnline,
    this.weeklyExpenseWeekStart,
    this.hasCompletedAppTour = false,
    this.seenScreenTutorials = const <String>[],
  });

  final RateType rateType;
  final double customRate;
  final double? warningLimit;
  final double lastRateBcv;
  final double lastRateParalelo;
  final bool? isOnline;
  final DateTime? weeklyExpenseWeekStart;
  final bool hasCompletedAppTour;
  final List<String> seenScreenTutorials;

  AppSettings copyWith({
    RateType? rateType,
    double? customRate,
    double? warningLimit,
    bool clearWarningLimit = false,
    double? lastRateBcv,
    double? lastRateParalelo,
    bool? isOnline,
    bool clearIsOnline = false,
    DateTime? weeklyExpenseWeekStart,
    bool clearWeeklyExpenseWeekStart = false,
    bool? hasCompletedAppTour,
    List<String>? seenScreenTutorials,
  }) {
    return AppSettings(
      rateType: rateType ?? this.rateType,
      customRate: customRate ?? this.customRate,
      warningLimit: clearWarningLimit ? null : (warningLimit ?? this.warningLimit),
      lastRateBcv: lastRateBcv ?? this.lastRateBcv,
      lastRateParalelo: lastRateParalelo ?? this.lastRateParalelo,
      isOnline: clearIsOnline ? null : (isOnline ?? this.isOnline),
      weeklyExpenseWeekStart: clearWeeklyExpenseWeekStart
          ? null
          : (weeklyExpenseWeekStart ?? this.weeklyExpenseWeekStart),
      hasCompletedAppTour: hasCompletedAppTour ?? this.hasCompletedAppTour,
      seenScreenTutorials: seenScreenTutorials ?? this.seenScreenTutorials,
    );
  }

  Map<String, dynamic> toJson() => {
        'rateType': rateType.value,
        'customRate': customRate,
        'warningLimit': warningLimit,
        'lastRateBcv': lastRateBcv,
        'lastRateParalelo': lastRateParalelo,
        if (weeklyExpenseWeekStart != null)
          'weeklyExpenseWeekStart': _formatDate(weeklyExpenseWeekStart!),
        'hasCompletedAppTour': hasCompletedAppTour,
        'seenScreenTutorials': seenScreenTutorials,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        rateType: RateType.fromString(json['rateType'] as String?),
        customRate: (json['customRate'] as num?)?.toDouble() ?? Defaults.defaultBsToUsdRate,
        warningLimit: (json['warningLimit'] as num?)?.toDouble(),
        lastRateBcv: (json['lastRateBcv'] as num?)?.toDouble() ?? Defaults.rateBcvFallback,
        lastRateParalelo:
            (json['lastRateParalelo'] as num?)?.toDouble() ?? Defaults.rateParaleloFallback,
        weeklyExpenseWeekStart: _parseDate(json['weeklyExpenseWeekStart'] as String?),
        hasCompletedAppTour: json['hasCompletedAppTour'] as bool? ?? false,
        seenScreenTutorials: (json['seenScreenTutorials'] as List?)?.cast<String>() ?? const <String>[],
      );

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
