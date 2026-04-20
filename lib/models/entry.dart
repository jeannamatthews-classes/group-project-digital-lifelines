// A single recorded point inside a timeline.
class Entry {
  final int? id;
  final int timelineId;
  final int createdAt;
  final bool isFavorite;

  Entry({
    this.id,
    required this.timelineId,
    required this.createdAt,
    this.isFavorite = false,
  });

  // Converts this model to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timeline_id': timelineId,
      'created_at': createdAt,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  // Rebuilds the model from a SQLite row.
  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as int?,
      timelineId: map['timeline_id'] as int,
      createdAt: map['created_at'] as int,
      isFavorite: ((map['is_favorite'] ?? 0) as int) == 1,
    );
  }
}
