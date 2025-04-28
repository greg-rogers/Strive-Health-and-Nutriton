import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'profile.dart';
import 'notifications.dart';
import 'nutrition_details.dart';
import '../helpers/navigation_helper.dart';
import '../helpers/goal_utils.dart';
import '../helpers/formatting_utils.dart';
import '../widgets/goal_ring.dart';
import '../services/streak_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  num calorieGoal = 2500;
  num calorieIntake = 0;
  bool isLoading = true;

  int workoutStreak = 0;
  int nutritionStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadCalorieData();
    _loadStreaks();
  }

  Future<void> _loadCalorieData() async {
    final result = await fetchGoalsAndTotals(DateTime.now());
    final totals = result.totals;

    setState(() {
      calorieGoal = result.calorieGoal;
      calorieIntake = totals['calories'] ?? 0;
      isLoading = false;
    });
  }

  Future<void> _loadStreaks() async {
    final w = await StreakService.getWorkoutStreak();
    final n = await StreakService.getNutritionStreak();
    setState(() {
      workoutStreak = w;
      nutritionStreak = n;
    });
  }

  void _openProfile() {
    navigateWithNavBar(context, const ProfileScreen(), initialIndex: 0);
  }

  void _openNotifications() {
    navigateWithNavBar(context, const NotificationsScreen(), initialIndex: 0);
  }

  void _openNutritionDetails() {
    navigateWithNavBar(
      context,
      NutritionDetailsScreen(selectedDate: DateTime.now()),
      initialIndex: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Strive', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        actions: [
          if (currentUser != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .collection('notifications')
                  .where('seen', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unseenCount = snapshot.data?.docs.length ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: _openNotifications,
                    ),
                    if (unseenCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Text(
                            unseenCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("👋 Welcome back!", style: Theme.of(context).textTheme.headlineSmall),
          Text("Here's a quick overview for $today", style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 20),

          // Calories Ring Preview
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoalRingWidget(
              title: "Calories",
              centreLabel: "${(calorieGoal - calorieIntake).round()} kcal Remaining",
              progress: calorieIntake / calorieGoal,
              metrics: [
                {"Goal": formatCalories(calorieGoal)},
                {"Intake": formatCalories(calorieIntake)},
              ],
              metricColors: {
                "Intake": getGoalStatus(type: "calories", intake: calorieIntake, goal: calorieGoal).color,
              },
              onTap: _openNutritionDetails,
            ),

          const SizedBox(height: 8),
          const Text("Tap the ring above to view all your nutrition details", textAlign: TextAlign.center),

          const SizedBox(height: 24),

          // Activity Summary Widget
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("🏃 Activity Today", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text("• 45 mins workout\n• 6,500 steps\n• 2 workouts logged"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Streaks Widget
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.local_fire_department, size: 36, color: Colors.deepOrange),
                      SizedBox(width: 12),
                      Text("Your Current Streaks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStreakBox("💪 Workouts", workoutStreak),
                      _buildStreakBox("🥗 Nutrition", nutritionStreak),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBox(String label, int days) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.local_fire_department, size: 20, color: Colors.deepOrange),
                SizedBox(width: 6),
              ],
            ),
            Text(
              "$days days",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
