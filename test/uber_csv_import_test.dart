import 'package:digital_lifelines/data/uber_csv_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups completed Uber Eats item rows into one restaurant entry', () {
    final payload = parseUberCsv('''
order_uuid,restaurant_name,request_time_local,order_status,item_name,order_price,currency,restaurant_rating
order-1,"Cafe, Inc. (10 Main St)",2026-06-28 19:03:00,completed,"Soup, large",22.50,USD,4.5
order-1,"Cafe, Inc. (10 Main St)",2026-06-28 19:03:00,completed,Salad,22.50,USD,4.5
order-2,"Cafe, Inc. (10 Main St)",2026-06-29 12:00:00,completed,Cookie,5.00,USD,
order-3,Other Place,2026-06-30 12:00:00,failed,Burger,15.00,USD,
''');

    final timeline = (payload['timelines'] as List).single;
    final entries = timeline['entries'] as List;
    expect(timeline['name'], 'Favorite Restaurants');
    expect(entries, hasLength(2));
    expect(entries[0]['values'], {
      'Name': 'Cafe, Inc.',
      'Address': '10 Main St',
      'Rating': '4.5',
      'Best Meal': 'Soup, large\nSalad',
      'Import_ID': 'uber:eats:order-1',
    });
    expect(entries[1]['values']['Import_ID'], 'uber:eats:order-2');
    expect(entries[1]['values']['Best Meal'], 'Cookie');
  });

  test('imports completed rides into Places and skips failed requests', () {
    final payload = parseUberCsv('''
request_timestamp_local,destination_string,status,is_completed,city_name,begintrip_string,trip_distance_miles,trip_duration_seconds,original_fare_local,currency_code,destination_lat,destination_lng
2026-06-28 19:03:00,"200 Main St, Potsdam, NY, US",completed,true,Potsdam,"10 Oak St, Potsdam, NY",4.2,600,18.75,USD,44.67,-74.98
2026-06-29 12:00:00,Airport,rider_canceled,false,Potsdam,Home,0,0,0,USD,,
''');

    final timeline = (payload['timelines'] as List).single;
    final entries = timeline['entries'] as List;
    expect(timeline['name'], 'Places');
    expect(entries, hasLength(1));
    expect(entries.single['values'], {
      'Date': '2026-06-28',
      'Country': 'United States',
      'State': 'New York',
      'City': 'Potsdam',
      'Latitude': '44.67',
      'Longitude': '-74.98',
      'Destination': '200 Main St, Potsdam',
      'Import_ID':
          'uber:ride|2026-06-28 19:03:00|||200 Main St, Potsdam, NY, US',
    });
  });

  test('groups DoorDash items by order and omits the delivery address', () {
    final payload = parseDoorDashCsv('''
ITEM,CATEGORY,STORE_NAME,UNIT_PRICE,QUANTITY,SUBTOTAL,CREATED_AT,DELIVERY_TIME,DELIVERY_ADDRESS,RESTAURANT_RATING
"Soup, large",Entrees,"Cafe, Place",9.99,2,19.98,2026-11-15 23:46:24.682000000,2026-11-15 23:56:39.306000000,"123 Private St",4.5
Tea,Drinks,"Cafe, Place",2.50,1,2.50,2026-11-15 23:46:24.682000000,2026-11-15 23:56:39.306000000,"123 Private St",4.5
Cookie,Desserts,"Cafe, Place",3.00,1,3.00,2026-11-14 18:00:00.000000000,2026-11-14 18:10:00.000000000,"123 Private St",4.5
''');

    final timeline = (payload['timelines'] as List).single;
    final entries = timeline['entries'] as List;
    expect(timeline['name'], 'Favorite Restaurants');
    expect(entries, hasLength(2));
    expect(entries.first['created_at'], isA<int>());
    expect(entries.first['values'], {
      'Name': 'Cafe, Place',
      'Address': '',
      'Rating': '4.5',
      'Best Meal': 'Soup, large x2\nTea',
      'Import_ID':
          'doordash:2026-11-15 23:46:24.682000000|2026-11-15 23:56:39.306000000|Cafe, Place',
    });
    expect(entries.last['values']['Best Meal'], 'Cookie');
    expect(
      entries.map((entry) => entry['values']['Import_ID']).toSet(),
      hasLength(2),
    );
  });

  test('handles escaped quotes and rejects an unrecognized CSV', () {
    final payload = parseUberCsv('''
order_uuid,restaurant_name,request_time_local,order_status,item_name
order-1,"Joe ""The Cook"" Cafe",2026-06-28 19:03:00,completed,Meal
''');
    final values =
        ((payload['timelines'] as List).single['entries'] as List)
                .single['values']
            as Map<String, dynamic>;
    expect(values['Name'], 'Joe "The Cook" Cafe');

    expect(
      () => parseUberCsv('not,an,uber,file\n1,2,3'),
      throwsFormatException,
    );
  });

  test('hides import metadata while keeping requested fields visible', () {
    expect(isHiddenImportField('Places', 'Import_ID'), isTrue);
    expect(isHiddenImportField('Places', 'Uber_ID'), isTrue);
    expect(isHiddenImportField('Places', 'Fare'), isTrue);
    expect(isHiddenImportField('Favorite Restaurants', 'Order_Total'), isTrue);
    expect(isHiddenImportField('Places', 'Destination'), isFalse);
    expect(isHiddenImportField('Favorite Restaurants', 'Rating'), isFalse);
  });
}
