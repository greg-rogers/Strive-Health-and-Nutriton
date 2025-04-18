/// Returns a string like "150" or "32.5"
String formatNumber(num value) {
  final str = value.toStringAsFixed(1);
  return str.endsWith('.0') ? str.replaceAll('.0', '') : str;
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

