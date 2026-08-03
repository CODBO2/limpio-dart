import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/defaults.dart';
import '../models/activity.dart';
import '../models/topic.dart';
import '../models/trash_entry.dart';
import '../services/storage_service.dart';
import 'activities_provider.dart';
import 'app_providers.dart';
import 'topics_provider.dart';

class TrashNotifier extends StateNotifier<List<TrashEntry>> {
  TrashNotifier(this._storage, this._ref) : super([]);

  final StorageService _storage;
  final Ref _ref;
  int _lastBatchSize = 1;

  Future<void> load() async {
    state = _storage.loadTrash();
  }

  Future<void> moveToTrash(Activity activity) async {
    await _ref.read(activitiesProvider.notifier).removeById(activity.id);
    state = [...state, TrashEntry.activity(activity)];
    _lastBatchSize = 1;
    await _storage.saveTrash(state);
  }

  Future<void> moveToTrashMany(List<Activity> items) async {
    if (items.isEmpty) return;
    await _ref
        .read(activitiesProvider.notifier)
        .removeByIds(items.map((a) => a.id).toList());
    state = [...state, ...items.map(TrashEntry.activity)];
    _lastBatchSize = items.length;
    await _storage.saveTrash(state);
  }

  Future<void> moveTopicToTrash(Topic topic) async {
    if (TopicsNotifier.isDefault(topic)) return;

    final linked = _ref
        .read(activitiesProvider)
        .where((a) => a.topicId == topic.id)
        .toList();

    await _ref.read(topicsProvider.notifier).remove(topic.id);
    if (linked.isNotEmpty) {
      await _ref
          .read(activitiesProvider.notifier)
          .removeByIds(linked.map((a) => a.id).toList());
    }

    state = [
      ...state,
      ...linked.map(TrashEntry.activity),
      TrashEntry.topic(topic),
    ];
    await _storage.saveTrash(state);
  }

  Future<void> restore(TrashEntry entry) async {
    if (entry.isTopic) {
      await _restoreTopic(entry.topic!);
    } else {
      await _restoreActivity(entry.activity!);
    }
  }

  Future<void> restoreActivity(Activity activity) => _restoreActivity(activity);

  Future<void> _restoreActivity(Activity activity) async {
    state = state
        .where((e) => !(e.isActivity && e.activity!.id == activity.id))
        .toList();
    await _storage.saveTrash(state);
    await _ref.read(activitiesProvider.notifier).add(activity);
  }

  Future<void> _restoreTopic(Topic topic) async {
    final linked = state
        .where((e) => e.isActivity && e.activity!.topicId == topic.id)
        .map((e) => e.activity!)
        .toList();

    state = state
        .where(
          (e) =>
              !(e.isTopic && e.topic!.id == topic.id) &&
              !(e.isActivity && e.activity!.topicId == topic.id),
        )
        .toList();
    await _storage.saveTrash(state);
    await _ref.read(topicsProvider.notifier).restore(topic);
    if (linked.isNotEmpty) {
      await _ref.read(activitiesProvider.notifier).restoreAll(linked);
    }
  }

  Future<void> emptyAll() async {
    state = [];
    await _storage.saveTrash(state);
  }

  Future<void> undoLastDelete() async {
    if (state.isEmpty) return;
    final count = _lastBatchSize.clamp(1, state.length);
    _lastBatchSize = 1;
    for (var i = 0; i < count; i++) {
      if (state.isEmpty) break;
      await restore(state.last);
    }
  }
}

final trashProvider =
    StateNotifierProvider<TrashNotifier, List<TrashEntry>>((ref) {
  return TrashNotifier(ref.watch(storageServiceProvider), ref);
});

final showUndoProvider = StateProvider<bool>((ref) => false);

/// Shows/hides the global "Deshacer" bar with a timeout that does not depend
/// on any widget's [mounted] flag.
class UndoController {
  UndoController(this._ref);

  final Ref _ref;
  Timer? _hideTimer;

  void show({
    Duration duration =
        const Duration(seconds: Defaults.undoDurationSeconds),
  }) {
    _hideTimer?.cancel();
    _ref.read(showUndoProvider.notifier).state = true;
    _hideTimer = Timer(duration, () {
      _ref.read(showUndoProvider.notifier).state = false;
      _hideTimer = null;
    });
  }

  void hide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _ref.read(showUndoProvider.notifier).state = false;
  }
}

final undoControllerProvider = Provider<UndoController>((ref) {
  final controller = UndoController(ref);
  ref.onDispose(controller.hide);
  return controller;
});
