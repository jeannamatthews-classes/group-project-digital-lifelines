class PhotoLocation {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? date;

  const PhotoLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.date,
  });

  String get displayName {
    if (city != null && city!.trim().isNotEmpty) {
      return city!;
    }

    return 'Location';
  }
}