import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_testing/helpers/formatting_utils.dart';

class StreakService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔥 Get streak of consecutive days with workouts logged
  static Future<int> getWorkoutStreak() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final uid = user.uid;
    DateTime current = DateTime.now();
    int streak = 0;

    while (true) {
      final docId = getFirestoreDateKey(current);
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('workoutLogs')
          .doc(docId)
          .get();

      if (doc.exists && doc.data()?['logged'] == true) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  static Future<int> getNutritionStreak() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final uid = user.uid;
    DateTime current = DateTime.now();
    int streak = 0;

    while (true) {
      final docId = getFirestoreDateKey(current);
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('nutritionLogs')
          .doc(docId)
          .get();

      if (doc.exists && (doc.data()?['logged'] == true)) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }


  static Future<void> incrementWorkoutStreak(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docId = getFirestoreDateKey(date);
    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('workoutLogs')
        .doc(docId);

    final existing = await docRef.get();

    // Only set it if it hasn't been marked as logged yet
    if (!existing.exists || existing.data()?['logged'] != true) {
      await docRef.set({'logged': true});
    }
  }
  static Future<void> incrementNutritionStreak(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docId = getFirestoreDateKey(date);
    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('nutritionLogs')
        .doc(docId);

    final existing = await docRef.get();
    final data = existing.data() ?? {};

    if (data['logged'] == true) {
      // Already marked, no need to update
      return;
    }

    await docRef.set({
      'logged': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


}
