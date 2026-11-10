import 'package:digital_lifelines/database/db_helper.dart';
import 'package:digital_lifelines/data/timeline_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'provides importable empty defaults with matching field definitions',
    () {
      final template = DBHelper.instance.buildTemplateJson();
      final timelines = template['timelines'] as List<Map<String, dynamic>>;

      expect(timelines.map((timeline) => timeline['name']).toList(), [
        'Favorite Restaurants',
        'Books',
        'Songs',
        'Places',
      ]);
      expect(
        timelines.every(
          (timeline) => (timeline['entries'] as List<dynamic>).isEmpty,
        ),
        isTrue,
      );
      expect(timelines[0]['fields'], [
        {'name': 'Name', 'type': 'text'},
        {'name': 'Address', 'type': 'text'},
        {'name': 'Rating', 'type': 'number'},
        {'name': 'Best Meal', 'type': 'text'},
      ]);
      expect(timelines[1]['fields'], [
        {'name': 'Book', 'type': 'text'},
        {'name': 'Rating', 'type': 'text'},
        {'name': 'Read_Status', 'type': 'text'},
        {'name': 'Review', 'type': 'text'},
        {'name': 'Includes_Spoilers', 'type': 'text'},
        {'name': 'Notes', 'type': 'text'},
        {'name': 'Updated_At', 'type': 'text'},
      ]);
      expect(timelines[2]['fields'], [
        {'name': 'Track', 'type': 'text'},
        {'name': 'Artist', 'type': 'text'},
        {'name': 'End_Time', 'type': 'text'},
        {'name': 'Ms_Played', 'type': 'number'},
      ]);
      expect(timelines[3]['fields'], [
        {'name': 'Date', 'type': 'text'},
        {'name': 'Country', 'type': 'text'},
        {'name': 'City', 'type': 'text'},
        {'name': 'Latitude', 'type': 'text'},
        {'name': 'Longitude', 'type': 'text'},
      ]);
    },
  );

  test('maps legacy import names to their default lifelines', () {
    expect(canonicalTimelineName('Spotify Streaming History'), 'Songs');
    expect(canonicalTimelineName('Goodreads Reviews'), 'Books');
    expect(canonicalTimelineName('My Places'), 'Places');
    expect(
      canonicalTimelineName('Favorite Restaurants'),
      'Favorite Restaurants',
    );
  });
}
