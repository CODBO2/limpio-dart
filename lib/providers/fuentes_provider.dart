import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/fuente.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

const _uuid = Uuid();

class FuentesNotifier extends StateNotifier<List<Fuente>> {
  FuentesNotifier(this._storage) : super([]);

  final StorageService _storage;

  Future<void> load() async {
    state = _storage.loadFuentes();
  }

  Future<void> add({
    required String name,
    required String amount,
    required String currency,
    required int day,
  }) async {
    final fuente = Fuente(
      id: _uuid.v4(),
      name: name,
      amount: amount,
      currency: currency,
      day: day,
    );
    state = [...state, fuente];
    await _storage.saveFuentes(state);
  }

  Future<void> update(Fuente fuente) async {
    state = [
      for (final item in state)
        if (item.id == fuente.id) fuente else item,
    ];
    await _storage.saveFuentes(state);
  }

  Future<void> remove(String id) async {
    state = state.where((f) => f.id != id).toList();
    await _storage.saveFuentes(state);
  }
}

final fuentesProvider = StateNotifierProvider<FuentesNotifier, List<Fuente>>((ref) {
  return FuentesNotifier(ref.watch(storageServiceProvider));
});
