import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> setGoal(String goalType, num value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc('main')
        .set({goalType: value}, SetOptions(merge: true));
  }

  static Future<num?> getGoal(String goalType) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .doc('main')
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final value = data[goalType];
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
    }
    return null;
  }

  static Future<num?> getCalorieGoal() => getGoal('calorieGoal');
  static Future<num?> getWaterGoal() => getGoal('waterGoal');
  static Future<num?> getSleepGoal() => getGoal('sleepGoal');

  static Future<void> setCalorieGoal(num value) => setGoal('calorieGoal', value);
  static Future<void> setWaterGoal(num value) => setGoal('waterGoal', value);
  static Future<void> setSleepGoal(num value) => setGoal('sleepGoal', value);

  static Future<num?> getCarbGoal() => getGoal('carbGoal');
  static Future<num?> getProteinGoal() => getGoal('proteinGoal');
  static Future<num?> getFatGoal() => getGoal('fatGoal');

  static Future<void> setCarbGoal(num value) => setGoal('carbGoal', value);
  static Future<void> setProteinGoal(num value) => setGoal('proteinGoal', value);
  static Future<void> setFatGoal(num value) => setGoal('fatGoal', value);

}
