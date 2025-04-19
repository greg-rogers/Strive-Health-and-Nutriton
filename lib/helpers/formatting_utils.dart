import 'package:flutter/material.dart';

// Returns a string like "150" or "32.5", with configurable decimal precision.
String formatNumber(num value, {int decimals = 1, bool stripTrailingZero = true}) {
  final str = value.toStringAsFixed(decimals);
  if (stripTrailingZero && str.endsWith('.0')) {
    return str.replaceAll('.0', '');
  }
  return str;
}

// Returns Firestore-friendly date string
String getFirestoreDateKey(DateTime date) =>
    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

// Parses number
double parseNumber(dynamic val) {
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}


Color getConsumedColor(double percent, double goal) {
  final consumedPercent = percent * 100;
  final diff = (consumedPercent - goal).abs();

  if (diff <= 5) return Colors.green;
  if (diff <= 15) return Colors.orangeAccent;
  return Colors.redAccent;
}

double macroToCalories(double grams, String type) {
  switch (type) {
    case 'fat':
      return grams * 9;
    case 'carbs':
    case 'protein':
    default:
      return grams * 4;
  }
}

String formatUnit(num value, String unit, {int decimals = 0}) {
  return "${formatNumber(value, decimals: decimals)} $unit";
}

String formatCalories(num value) => value.round().toString();

