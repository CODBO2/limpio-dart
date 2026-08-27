import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/fixed_expense_preset.dart';
import '../models/payment_method.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

const _uuid = Uuid();

class FixedExpensePresetsNotifier
    extends StateNotifier<List<FixedExpensePreset>> {
  FixedExpensePresetsNotifier(this._storage) : super([]);

  final StorageService _storage;

  Future<void> load() async {
    state = _storage.loadFixedExpensePresets();
  }

  List<FixedExpensePreset> forTopic(String topicId) =>
      state.where((p) => p.topicId == topicId).toList();

  Future<void> add({
    required String topicId,
    required String title,
    required String amount,
    required String currency,
    PaymentMethod paymentMethod = PaymentMethod.cashUsd,
  }) async {
    final preset = FixedExpensePreset(
      id: _uuid.v4(),
      topicId: topicId,
      title: title.trim(),
      amount: amount.trim(),
      currency: currency,
      paymentMethod: paymentMethod,
    );
    state = [...state, preset];
    await _storage.saveFixedExpensePresets(state);
  }

  Future<void> update(FixedExpensePreset preset) async {
    state = [
      for (final item in state)
        if (item.id == preset.id) preset else item,
    ];
    await _storage.saveFixedExpensePresets(state);
  }

  Future<void> remove(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _storage.saveFixedExpensePresets(state);
  }

  Future<void> removeByTopic(String topicId) async {
    final next = state.where((p) => p.topicId != topicId).toList();
    if (next.length == state.length) return;
    state = next;
    await _storage.saveFixedExpensePresets(state);
  }
}

final fixedExpensePresetsProvider = StateNotifierProvider<
    FixedExpensePresetsNotifier, List<FixedExpensePreset>>((ref) {
  return FixedExpensePresetsNotifier(ref.watch(storageServiceProvider));
});
