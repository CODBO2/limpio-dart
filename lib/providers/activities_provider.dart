import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/defaults.dart';
import '../models/activity.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

class ActivitiesNotifier extends StateNotifier<List<Activity>> {
  ActivitiesNotifier(this._storage) : super([]);

  final StorageService _storage;

  Future<void> load() async {
    state = _storage.loadActivities();
  }

  /// Assigns [Defaults.defaultTopicId] to activities with null/orphan topicId.
  Future<void> migrateUnassignedToDefault(Set<String> knownTopicIds) async {
    final defaultId = Defaults.defaultTopicId;
    var changed = false;
    final next = <Activity>[];
    for (final item in state) {
      final topicId = item.topicId;
      if (topicId == null || !knownTopicIds.contains(topicId)) {
        next.add(item.copyWith(topicId: defaultId));
        changed = true;
      } else {
        next.add(item);
      }
    }
    if (!changed) return;
    state = next;
    await _storage.saveActivities(state);
  }

  Future<void> add(Activity activity) async {
    final withTopic = activity.topicId == null
        ? activity.copyWith(topicId: Defaults.defaultTopicId)
        : activity;
    state = [withTopic, ...state];
    await _storage.saveActivities(state);
  }

  Future<void> update(Activity activity) async {
    state = [
      for (final item in state)
        if (item.id == activity.id) activity else item,
    ];
    await _storage.saveActivities(state);
  }

  Future<void> moveToTopic(List<String> ids, String topicId) async {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    state = [
      for (final item in state)
        if (idSet.contains(item.id)) item.copyWith(topicId: topicId) else item,
    ];
    await _storage.saveActivities(state);
  }

  Future<void> removeById(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _storage.saveActivities(state);
  }

  Future<void> removeByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    state = state.where((a) => !idSet.contains(a.id)).toList();
    await _storage.saveActivities(state);
  }

  Future<void> restoreAll(List<Activity> items) async {
    state = [...items, ...state];
    await _storage.saveActivities(state);
  }

  Future<void> replaceAll(List<Activity> items) async {
    state = items;
    await _storage.saveActivities(state);
  }
}

final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, List<Activity>>((ref) {
  return ActivitiesNotifier(ref.watch(storageServiceProvider));
});
