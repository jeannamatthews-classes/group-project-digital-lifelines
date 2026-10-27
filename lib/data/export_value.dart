Object exportValueForField(String fieldName, String value) {
  final normalizedFieldName = fieldName.trim().toLowerCase();
  if (normalizedFieldName != 'latitude' && normalizedFieldName != 'longitude') {
    return value;
  }

  final coordinate = double.tryParse(value);
  return coordinate != null && coordinate.isFinite ? coordinate : value;
}
