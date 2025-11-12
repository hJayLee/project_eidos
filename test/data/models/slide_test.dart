import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_eidos/data/models/slide.dart';

void main() {
  group('SlideData.fromJson', () {
    test('handles Firestore Timestamp for createdAt/updatedAt', () {
      final created = Timestamp.fromDate(DateTime(2024, 2, 10, 12));
      final updated = Timestamp.fromDate(DateTime(2024, 3, 12, 8));

      final slide = SlideData.fromJson({
        'id': 'slide-1',
        'title': '테스트 슬라이드',
        'elements': const [],
        'duration': 15,
        'layout': 'titleAndContent',
        'style': null,
        'createdAt': created,
        'updatedAt': updated,
        'order': 0,
        'metadata': const {},
      });

      expect(slide.createdAt, created.toDate());
      expect(slide.updatedAt, updated.toDate());
    });
  });
}

