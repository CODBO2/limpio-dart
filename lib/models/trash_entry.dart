import 'activity.dart';
import 'topic.dart';

enum TrashEntryType { activity, topic }

class TrashEntry {
  const TrashEntry.activity(Activity this.activity)
      : type = TrashEntryType.activity,
        topic = null;

  const TrashEntry.topic(Topic this.topic)
      : type = TrashEntryType.topic,
        activity = null;

  final TrashEntryType type;
  final Activity? activity;
  final Topic? topic;

  bool get isActivity => type == TrashEntryType.activity;
  bool get isTopic => type == TrashEntryType.topic;

  String get id => isActivity ? activity!.id : topic!.id;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (isActivity) 'activity': activity!.toJson(),
        if (isTopic) 'topic': topic!.toJson(),
      };

  factory TrashEntry.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == TrashEntryType.topic.name) {
      return TrashEntry.topic(
        Topic.fromJson(Map<String, dynamic>.from(json['topic'] as Map)),
      );
    }
    if (type == TrashEntryType.activity.name) {
      return TrashEntry.activity(
        Activity.fromJson(Map<String, dynamic>.from(json['activity'] as Map)),
      );
    }
    // Formato legado: actividad plana sin wrapper.
    return TrashEntry.activity(Activity.fromJson(json));
  }
}
