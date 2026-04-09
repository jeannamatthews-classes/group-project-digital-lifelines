class TimelineField {
  final int? id;
  final int timelineId;
  final String name;
  final String type;

  TimelineField({
    this.id,
    required this.timelineId,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'timeline_id': timelineId, 'name': name, 'type': type};
  }

  factory TimelineField.fromMap(Map<String, dynamic> map) {
    return TimelineField(
      id: map['id'] as int?,
      timelineId: map['timeline_id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
    );
  }
}
