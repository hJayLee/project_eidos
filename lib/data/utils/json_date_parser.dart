import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
  if (value == null) return fallback ?? DateTime.now();
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  if (value is num) {
    // Interpret numeric values as milliseconds since epoch.
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return fallback ?? DateTime.now();
}
