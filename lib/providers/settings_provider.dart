import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/amount_parser.dart';
import '../models/app_settings.dart';
import '../models/rate_type.dart';
import '../services/exchange_rate_service.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

class SettingsState {
  const SettingsState({
    required this.settings,
    this.ratesRefreshing = false,
  });

  final AppSettings settings;
  final bool ratesRefreshing;

  double get effectiveRate => getEffectiveRate(
        rateType: settings.rateType.value,
        customRate: settings.customRate,
        rateBcv: settings.lastRateBcv,
      );

  SettingsState copyWith({
    AppSettings? settings,
    bool? ratesRefreshing,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      ratesRefreshing: ratesRefreshing ?? this.ratesRefreshing,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._storage, this._exchangeRateService)
      : super(const SettingsState(settings: AppSettings()));

  final StorageService _storage;
  final ExchangeRateService _exchangeRateService;

  Future<void> load() async {
    final settings = _storage.loadSettings();
    state = SettingsState(settings: settings);
  }

  Future<void> setRateType(RateType rateType) async {
    final updated = state.settings.copyWith(rateType: rateType);
    state = state.copyWith(settings: updated);
    await _storage.saveSettings(updated);
  }

  Future<void> setCustomRate(double rate) async {
    final updated = state.settings.copyWith(customRate: rate);
    state = state.copyWith(settings: updated);
    await _storage.saveSettings(updated);
  }

  Future<void> setWarningLimit(double? limit) async {
    final updated = state.settings.copyWith(
      warningLimit: limit,
      clearWarningLimit: limit == null,
    );
    state = state.copyWith(settings: updated);
    await _storage.saveSettings(updated);
  }

  Future<void> setWeeklyExpenseWeekStart(DateTime weekStart) async {
    final updated = state.settings.copyWith(
      weeklyExpenseWeekStart: DateTime(weekStart.year, weekStart.month, weekStart.day),
    );
    state = state.copyWith(settings: updated);
    await _storage.saveSettings(updated);
  }

  Future<void> setHasCompletedAppTour(bool completed) async {
    final updated = state.settings.copyWith(hasCompletedAppTour: completed);
    state = state.copyWith(settings: updated);
    await _storage.saveSettings(updated);
  }

  Future<void> markScreenTutorialSeen(String screenId) async {
    if (state.settings.seenScreenTutorials.contains(screenId)) return;
    final updatedList = [...state.settings.seenScreenTutorials, screenId];
    final updated = state.settings.copyWith(seenScreenTutorials: updatedList);
    state = state.copyWith(settings: updated);
    await _storage.saveSettings(updated);
  }

  Future<void> setSeenScreenTutorials(List<String> seenTutorials) async {
    final updated = state.settings.copyWith(seenScreenTutorials: seenTutorials);
    state = state.copyWith(settings: updated);
    await _storage.saveSettings(updated);
  }

  Future<void> clearAllTutorials() async {
    final updated = state.settings.copyWith(
      hasCompletedAppTour: false,
      seenScreenTutorials: const <String>[],
    );
    state = state.copyWith(settings: updated);
    await _storage.saveSettings(updated);
  }

  Future<void> refreshRates() async {
    state = state.copyWith(ratesRefreshing: true);
    try {
      final bcv = await _exchangeRateService.fetchBcvRate();
      var updated = state.settings;
      final gotAny = bcv != null;

      if (bcv != null) {
        updated = updated.copyWith(lastRateBcv: bcv.promedio);
      }

      updated = updated.copyWith(isOnline: gotAny);
      state = state.copyWith(settings: updated, ratesRefreshing: false);
      await _storage.saveSettings(updated);
    } catch (_) {
      state = state.copyWith(
        settings: state.settings.copyWith(isOnline: false),
        ratesRefreshing: false,
      );
      await _storage.saveSettings(state.settings);
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(exchangeRateServiceProvider),
  );
});
