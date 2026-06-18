class Timeline {
  final int? id;
  final String name;

  Timeline({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Timeline.fromMap(Map<String, dynamic> map) {
    return Timeline(id: map['id'] as int?, name: map['name'] as String);
  }
}
