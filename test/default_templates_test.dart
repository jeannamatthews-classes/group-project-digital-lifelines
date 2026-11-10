import 'package:digital_lifelines/database/db_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'provides importable empty defaults with matching field definitions',
    () {
      final template = DBHelper.instance.buildTemplateJson();
      final timelines = template['timelines'] as List<Map<String, dynamic>>;

      expect(timelines.map((timeline) => timeline['name']).toList(), [
        'Spotify Streaming History',
        'Goodreads Reviews',
        'My Places',
        'Favorite Restaurants',
      ]);
      expect(
        timelines.every(
          (timeline) => (timeline['entries'] as List<dynamic>).isEmpty,
        ),
        isTrue,
      );
      expect(timelines.last['fields'], [
        {'name': 'Name', 'type': 'text'},
        {'name': 'Address', 'type': 'text'},
        {'name': 'Rating', 'type': 'number'},
        {'name': 'Best Meal', 'type': 'text'},
      ]);
    },
  );
}
