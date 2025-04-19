import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helpers/formatting_utils.dart';

class NutritionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> _meals = ["Breakfast", "Lunch", "Dinner", "Extras"];

  static Future<Map<String, num>> getDailyTotals(String dateStr) async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final uid = user.uid;

    num totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0, totalFibre = 0;

    for (String meal in _meals) {
      final snapshot = await _firestore
          .collection("users")
          .doc(uid)
          .collection("nutritionLogs")
          .doc(dateStr)
          .collection(meal)
          .get();

      final docs = snapshot.docs;
      totalCalories += _sumField(docs, 'calories');
      totalProtein  += _sumField(docs, 'protein');
      totalCarbs    += _sumField(docs, 'carbs');
      totalFat      += _sumField(docs, 'fat');
      totalFibre    += _sumField(docs, 'fibre');
    }

    final rootDoc = await _firestore
        .collection("users")
        .doc(uid)
        .collection("nutritionLogs")
        .doc(dateStr)
        .get();

    final root = rootDoc.data() ?? {};

    return {
      "calories": totalCalories,
      "protein": totalProtein,
      "carbs": totalCarbs,
      "fat": totalFat,
      "fibre": totalFibre,
      "water": parseNumber(root['water']),
      "sleep": parseNumber(root['sleep']),
    };
  }

  static num _sumField(List<QueryDocumentSnapshot> docs, String field) {
    return docs.fold(0.0, (total, doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return total + parseNumber(data?[field]);
    });
  }

}
