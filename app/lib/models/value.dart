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

  Map<String, dynamic> toMap() {
    return {'id': id, 'entry_id': entryId, 'field_id': fieldId, 'value': value};
  }

  factory EntryValue.fromMap(Map<String, dynamic> map) {
    return EntryValue(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int,
      fieldId: map['field_id'] as int,
      value: map['value'] as String,
    );
  }
}
