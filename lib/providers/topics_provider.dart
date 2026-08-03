import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/defaults.dart';
import '../models/topic.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

const _uuid = Uuid();

class TopicsNotifier extends StateNotifier<List<Topic>> {
  TopicsNotifier(this._storage) : super([]);

  final StorageService _storage;

  static bool isDefault(Topic topic) => topic.id == Defaults.defaultTopicId;

  static bool isDefaultId(String? id) => id == Defaults.defaultTopicId;

  Topic get defaultTopic => const Topic(
        id: Defaults.defaultTopicId,
        name: Defaults.defaultTopicName,
      );

  Future<void> load() async {
    state = _storage.loadTopics();
    await ensureDefault();
  }

  /// Guarantees the fixed «Por defecto» topic exists and stays first.
  Future<void> ensureDefault() async {
    final existingIndex =
        state.indexWhere((t) => t.id == Defaults.defaultTopicId);
    if (existingIndex >= 0) {
      final current = state[existingIndex];
      final needsNameFix = current.name != Defaults.defaultTopicName;
      final needsMove = existingIndex != 0;
      if (!needsNameFix && !needsMove) return;

      final fixed = needsNameFix
          ? current.copyWith(name: Defaults.defaultTopicName)
          : current;
      final rest = [
        for (final t in state)
          if (t.id != Defaults.defaultTopicId) t,
      ];
      state = [fixed, ...rest];
      await _storage.saveTopics(state);
      return;
    }

    state = [defaultTopic, ...state];
    await _storage.saveTopics(state);
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.toLowerCase() == Defaults.defaultTopicName.toLowerCase()) {
      return;
    }

    final topic = Topic(id: _uuid.v4(), name: trimmed);
    state = [...state, topic];
    await _storage.saveTopics(state);
  }

  Future<void> update(Topic topic) async {
    if (isDefault(topic)) {
      topic = topic.copyWith(name: Defaults.defaultTopicName);
    }
    state = [
      for (final item in state)
        if (item.id == topic.id) topic else item,
    ];
    await _storage.saveTopics(state);
  }

  Future<void> remove(String id) async {
    if (isDefaultId(id)) return;
    state = state.where((t) => t.id != id).toList();
    await _storage.saveTopics(state);
  }

  Future<void> restore(Topic topic) async {
    if (state.any((t) => t.id == topic.id)) return;
    if (isDefault(topic)) {
      await ensureDefault();
      return;
    }
    state = [...state, topic];
    await _storage.saveTopics(state);
  }
}

final topicsProvider = StateNotifierProvider<TopicsNotifier, List<Topic>>((ref) {
  return TopicsNotifier(ref.watch(storageServiceProvider));
});
