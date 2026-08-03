class Topic {
  const Topic({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  Topic copyWith({String? id, String? name}) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
