import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/storage_keys.dart';
import '../models/activity.dart';
import '../models/activity_builder.dart';
import '../models/app_settings.dart';
import '../models/fuente.dart';
import '../models/payment_card.dart';
import '../models/topic.dart';
import '../models/trash_entry.dart';

class StorageService {
  static const _settingsKey = 'app_settings';

  late Box<String> _activitiesBox;
  late Box<String> _fuentesBox;
  late Box<String> _topicsBox;
  late Box<String> _cardsBox;
  late Box<String> _trashBox;
  late Box<String> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _activitiesBox = await Hive.openBox<String>(StorageKeys.activitiesBox);
    _fuentesBox = await Hive.openBox<String>(StorageKeys.fuentesBox);
    _topicsBox = await Hive.openBox<String>(StorageKeys.topicsBox);
    _cardsBox = await Hive.openBox<String>(StorageKeys.cardsBox);
    _trashBox = await Hive.openBox<String>(StorageKeys.trashBox);
    _settingsBox = await Hive.openBox<String>(StorageKeys.settingsBox);
  }

  List<Activity> loadActivities() =>
      ActivityBuilder.activitiesFromJson(_activitiesBox.get('list'));

  Future<void> saveActivities(List<Activity> activities) async {
    await _activitiesBox.put('list', jsonEncode(ActivityBuilder.activitiesToJson(activities)));
  }

  List<Fuente> loadFuentes() => ActivityBuilder.fuentesFromJson(_fuentesBox.get('list'));

  Future<void> saveFuentes(List<Fuente> fuentes) async {
    await _fuentesBox.put('list', jsonEncode(ActivityBuilder.fuentesToJson(fuentes)));
  }

  List<Topic> loadTopics() => ActivityBuilder.topicsFromJson(_topicsBox.get('list'));

  Future<void> saveTopics(List<Topic> topics) async {
    await _topicsBox.put('list', jsonEncode(ActivityBuilder.topicsToJson(topics)));
  }

  List<PaymentCard> loadCards() => ActivityBuilder.cardsFromJson(_cardsBox.get('list'));

  Future<void> saveCards(List<PaymentCard> cards) async {
    await _cardsBox.put('list', jsonEncode(ActivityBuilder.cardsToJson(cards)));
  }

  List<TrashEntry> loadTrash() =>
      ActivityBuilder.trashFromJson(_trashBox.get('list'));

  Future<void> saveTrash(List<TrashEntry> trash) async {
    await _trashBox.put('list', jsonEncode(ActivityBuilder.trashToJson(trash)));
  }

  AppSettings loadSettings() {
    final raw = _settingsBox.get(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(_settingsKey, jsonEncode(settings.toJson()));
  }
}
