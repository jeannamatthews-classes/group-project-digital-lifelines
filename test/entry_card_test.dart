import 'package:digital_lifelines/models/entry.dart';
import 'package:digital_lifelines/models/field.dart';
import 'package:digital_lifelines/screens/timeline/widgets/entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Places cards use City as title and show dates without time', (
    tester,
  ) async {
    final fields = [
      TimelineField(id: 1, timelineId: 1, name: 'Date', type: 'text'),
      TimelineField(id: 2, timelineId: 1, name: 'Country', type: 'text'),
      TimelineField(id: 3, timelineId: 1, name: 'State', type: 'text'),
      TimelineField(id: 4, timelineId: 1, name: 'City', type: 'text'),
      TimelineField(id: 5, timelineId: 1, name: 'Destination', type: 'text'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EntryCard(
              entry: Entry(
                id: 7,
                timelineId: 1,
                createdAt: DateTime(2026, 6, 28, 19, 3).millisecondsSinceEpoch,
              ),
              fields: fields,
              valuesByFieldId: {
                1: '2026-06-28',
                2: 'United States',
                3: 'New York',
                4: 'Potsdam',
                5: '200 Main Street',
              },
              timelineName: 'Places',
              onToggleFavorite: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    final title = find.descendant(
      of: find.byType(Row).first,
      matching: find.text('Potsdam'),
    );
    expect(title, findsOneWidget);
    expect(find.text('06/28/2026'), findsOneWidget);
    expect(find.text('06/28/2026 19:03'), findsNothing);
    expect(find.text('COUNTRY'), findsOneWidget);
    expect(find.text('STATE'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('New York'), findsOneWidget);
  });
}
