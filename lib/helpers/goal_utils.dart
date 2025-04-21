import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../services/nutrition_service.dart';
import '../helpers/formatting_utils.dart';

class GoalStatus {
  final Color color;
  final bool goalMet;

  const GoalStatus({required this.color, required this.goalMet});
}

/// Returns a color + goalMet flag based on how close intake is to goal.
/// Goal met thresholds:
/// - Calories: within 5%
/// - Water: within 10%
/// - Sleep: within 13%
/// - Macros (carbs, protein, fat): within 5%
GoalStatus getGoalStatus({
  required num intake,
  required num goal,
  required String type,
}) {
  if (goal == 0) {
    return const GoalStatus(color: Colors.grey, goalMet: false);
  }

  final percent = (intake / goal).clamp(0.0, 2.0);
  final double tolerance = {
    'calories': 0.05,
    'water': 0.10,
    'sleep': 0.13,
    'carbs': 0.10,
    'protein': 0.10,
    'fat': 0.10,
  }[type.toLowerCase()] ?? 0.05;

  final isWithinGoal = (percent - 1.0).abs() <= tolerance;

  Color color;
  if (isWithinGoal) {
    color = Colors.green;
  } else if (percent >= 0.5) {
    color = Colors.orange;
  } else {
    color = Colors.red;
  }

  return GoalStatus(color: color, goalMet: isWithinGoal);
}

class GoalAndTotals {
  final num calorieGoal;
  final num waterGoal;
  final num sleepGoal;
  final Map<String, num> macroGoals; 
  final Map<String, num> macroGrams;
  final Map<String, num> totals;

  GoalAndTotals({
    required this.calorieGoal,
    required this.waterGoal,
    required this.sleepGoal,
    required this.macroGoals, 
    required this.macroGrams,
    required this.totals,
  });
}

Future<GoalAndTotals> fetchGoalsAndTotals(DateTime date) async {
  final dateStr = getFirestoreDateKey(date);

  final calorieGoal = await GoalService.getCalorieGoal() ?? 2500;
  final waterGoal = await GoalService.getWaterGoal() ?? 2000;
  final sleepGoal = await GoalService.getSleepGoal() ?? 8;

  final carbGoal = await GoalService.getCarbGoal() ?? 50;
  final proteinGoal = await GoalService.getProteinGoal() ?? 30;
  final fatGoal = await GoalService.getFatGoal() ?? 20;

  final totals = await NutritionService.getDailyTotals(dateStr);

  // 🔹 Convert macro percent goals into grams based on calorieGoal
  final macroGrams = {
    'carbs': (carbGoal / 100 * calorieGoal) / 4,
    'protein': (proteinGoal / 100 * calorieGoal) / 4,
    'fat': (fatGoal / 100 * calorieGoal) / 9,
  };

  return GoalAndTotals(
    calorieGoal: calorieGoal,
    waterGoal: waterGoal,
    sleepGoal: sleepGoal,
    macroGoals: {
      'carbs': carbGoal,
      'protein': proteinGoal,
      'fat': fatGoal,
    },
    macroGrams: macroGrams, 
    totals: totals,
  );
}
