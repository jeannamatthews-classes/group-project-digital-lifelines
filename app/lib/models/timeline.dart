// A top-level category (lifeline) such as Books, Spotify, or Travel.
class Timeline {
  final int? id;
  final String name;

  Timeline({this.id, required this.name});

  // Converts this model to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  // Rebuilds the model from a SQLite row.
  factory Timeline.fromMap(Map<String, dynamic> map) {
    return Timeline(id: map['id'] as int?, name: map['name'] as String);
  }
}
