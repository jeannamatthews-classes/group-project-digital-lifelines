import 'dart:io';
import 'package:exif/exif.dart';

class PhotoImportService {
  Future<Map<String, String>> extractExif(String path) async {
    final bytes = await File(path).readAsBytes();
    final data = await readExifFromBytes(bytes);

    String lat = "Not found";
    String lng = "Not found";
    String time = "Not found";

    if (data.containsKey('GPS GPSLatitude')) {
      lat = data['GPS GPSLatitude']!.printable;
    }

    if (data.containsKey('GPS GPSLongitude')) {
      lng = data['GPS GPSLongitude']!.printable;
    }

    if (data.containsKey('Image DateTime')) {
      time = data['Image DateTime']!.printable;
    }

    return {
      "latitude": lat,
      "longitude": lng,
      "time": time,
    };
  }
}