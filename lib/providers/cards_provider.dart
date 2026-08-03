import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_card.dart';
import '../services/storage_service.dart';
import 'activities_provider.dart';
import 'app_providers.dart';

const _uuid = Uuid();

class CardsNotifier extends StateNotifier<List<PaymentCard>> {
  CardsNotifier(this._storage, this._ref) : super([]);

  final StorageService _storage;
  final Ref _ref;

  Future<void> load() async {
    state = _storage.loadCards();
  }

  Future<void> add({
    required String name,
    required CardKind kind,
    String? lastFour,
    String? bank,
    String colorHex = '#1A1F2D',
    CardCurrencyMode currencyMode = CardCurrencyMode.bolivares,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final card = PaymentCard(
      id: _uuid.v4(),
      name: trimmed,
      kind: kind,
      lastFour: _normalizeLastFour(lastFour),
      bank: bank?.trim().isEmpty == true ? null : bank?.trim(),
      colorHex: colorHex,
      currencyMode: currencyMode,
    );
    state = [...state, card];
    await _storage.saveCards(state);
  }

  Future<void> update(PaymentCard card) async {
    state = [
      for (final item in state)
        if (item.id == card.id) card else item,
    ];
    await _storage.saveCards(state);
  }

  Future<void> remove(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _storage.saveCards(state);

    final activities = _ref.read(activitiesProvider);
    if (activities.any((a) => a.cardId == id)) {
      final updated = activities
          .map((a) => a.cardId == id ? a.copyWith(clearCardId: true) : a)
          .toList();
      await _ref.read(activitiesProvider.notifier).replaceAll(updated);
    }
  }

  String? _normalizeLastFour(String? value) {
    if (value == null) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return digits.length > 4 ? digits.substring(digits.length - 4) : digits;
  }
}

final cardsProvider = StateNotifierProvider<CardsNotifier, List<PaymentCard>>((ref) {
  return CardsNotifier(ref.watch(storageServiceProvider), ref);
});
