import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_eidos/data/utils/json_date_parser.dart';

void main() {
  group('parseDateTime', () {
    test('parses ISO8601 string', () {
      final date = parseDateTime('2024-05-01T12:30:00.000Z');
      expect(date.year, 2024);
      expect(date.month, 5);
      expect(date.day, 1);
    });

    test('parses Firestore Timestamp', () {
      final timestamp = Timestamp.fromMillisecondsSinceEpoch(1_700_000_000_000);
      final date = parseDateTime(timestamp);
      expect(date.millisecondsSinceEpoch, timestamp.millisecondsSinceEpoch);
    });

    test('returns fallback when null', () {
      final fallback = DateTime(2023, 1, 1);
      final date = parseDateTime(null, fallback: fallback);
      expect(date, fallback);
    });
  });
}

