import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/defaults.dart';
import '../core/utils/amount_parser.dart';
import '../providers/activities_provider.dart';
import '../providers/settings_provider.dart';

export '../core/utils/amount_parser.dart' show BalanceTotals;

final balanceProvider = Provider<BalanceTotals>((ref) {
  final activities = ref.watch(activitiesProvider);
  final effectiveRate = ref.watch(settingsProvider).effectiveRate;
  return BalanceCalculator.computeTotals(activities, rate: effectiveRate);
});

final effectiveRateProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).effectiveRate;
});

final warningLimitProvider = Provider<double?>((ref) {
  return ref.watch(settingsProvider).settings.warningLimit;
});

final undoDurationProvider = Provider<Duration>((ref) {
  return const Duration(seconds: Defaults.undoDurationSeconds);
});
