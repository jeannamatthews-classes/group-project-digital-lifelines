// Stores one field value for a specific entry.
class EntryValue {
  final int? id;
  final int entryId;
  final int fieldId;
  final String value;

  EntryValue({
    this.id,
    required this.entryId,
    required this.fieldId,
    required this.value,
  });

  // Converts this model to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {'id': id, 'entry_id': entryId, 'field_id': fieldId, 'value': value};
  }

  // Rebuilds the model from a SQLite row.
  factory EntryValue.fromMap(Map<String, dynamic> map) {
    return EntryValue(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int,
      fieldId: map['field_id'] as int,
      value: map['value'] as String,
    );
  }
}
