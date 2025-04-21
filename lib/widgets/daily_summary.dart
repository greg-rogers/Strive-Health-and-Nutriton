import 'package:flutter/material.dart';
import 'package:flutter_testing/helpers/goal_utils.dart';
import 'package:flutter_testing/screens/nutrition.dart';
import 'package:table_calendar/table_calendar.dart';
import '../helpers/formatting_utils.dart';
import '../helpers/navigation_helper.dart';
import '../screens/add_food.dart';
import '../screens/add_water_sleep.dart';

class DailySummarySheet extends StatelessWidget {
  final num waterIntake;
  final num sleepHours;
  final num calorieIntake;
  final num waterGoal;
  final num sleepGoal;
  final num calorieGoal;
  final VoidCallback? onAddWater;
  final VoidCallback? onAddSleep;
  final VoidCallback? onAddFood;
  final VoidCallback? onConfirm;

  final bool showCalories;
  final bool showWater;
  final bool showSleep;

  final bool isForToday;
  final DateTime selectedDate;

  final Map<String, Color> metricColors;

  final bool openedFromCalendar;

  const DailySummarySheet({
    super.key,
    required this.waterIntake,
    required this.sleepHours,
    required this.calorieIntake,
    required this.waterGoal,
    required this.sleepGoal,
    required this.calorieGoal,
    required this.selectedDate,
    required this.isForToday,
    required this.metricColors,
    this.onAddWater,
    this.onAddSleep,
    this.onAddFood,
    this.onConfirm,
    this.showCalories = true,
    this.showWater = true,
    this.showSleep = true,
    this.openedFromCalendar = false,
  });

  /// 🔹 Nutrition page version — always shows all 3 metrics
  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required bool isForToday,
  }) async {
    print("📩 Showing full summary (from NutritionScreen)");
    final result = await fetchGoalsAndTotals(date);
    final totals = result.totals;

    final metricColors = {
      'calories': getGoalStatus(type: 'calories', intake: totals['calories'] ?? 0, goal: result.calorieGoal).color,
      'water': getGoalStatus(type: 'water', intake: totals['water'] ?? 0, goal: result.waterGoal).color,
      'sleep': getGoalStatus(type: 'sleep', intake: totals['sleep'] ?? 0, goal: result.sleepGoal).color,
    };

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DailySummarySheet(
        showCalories: true,
        showWater: true,
        showSleep: true,
        openedFromCalendar: false,
        isForToday: isForToday,
        selectedDate: date,
        calorieIntake: totals['calories'] ?? 0,
        waterIntake: totals['water'] ?? 0,
        sleepHours: totals['sleep'] ?? 0,
        calorieGoal: result.calorieGoal,
        waterGoal: result.waterGoal,
        sleepGoal: result.sleepGoal,
        metricColors: metricColors,
        onConfirm: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Log completed for the day!")),
          );
        },
        onAddFood: () {
          Navigator.pop(context);
          navigateWithNavBar(
            context,
            AddFoodScreen(mealType: "Breakfast", selectedDate: date),
            initialIndex: 2,
          );
        },
        onAddWater: () {
          Navigator.pop(context);
          navigateWithNavBar(
            context,
            WaterSleepLoggerScreen(type: 'water', selectedDate: date),
            initialIndex: 2,
          );
        },
        onAddSleep: () {
          Navigator.pop(context);
          navigateWithNavBar(
            context,
            WaterSleepLoggerScreen(type: 'sleep', selectedDate: date),
            initialIndex: 2,
          );
        },
        
      ),
    );
  }

  static Future<void> showFilteredSummary(
    BuildContext context, {
    required DateTime date,
    required bool showCalories,
    required bool showWater,
    required bool showSleep,
  }) async {
    final result = await fetchGoalsAndTotals(date);
    final totals = result.totals;

    final metricColors = {
      if (showCalories)
        'calories': getGoalStatus(
          type: 'calories',
          intake: totals['calories'] ?? 0,
          goal: result.calorieGoal,
        ).color,
      if (showWater)
        'water': getGoalStatus(
          type: 'water',
          intake: totals['water'] ?? 0,
          goal: result.waterGoal,
        ).color,
      if (showSleep)
        'sleep': getGoalStatus(
          type: 'sleep',
          intake: totals['sleep'] ?? 0,
          goal: result.sleepGoal,
        ).color,
    };

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DailySummarySheet(
        isForToday: isSameDay(date, DateTime.now()),
        selectedDate: date,
        calorieIntake: totals['calories'] ?? 0,
        waterIntake: totals['water'] ?? 0,
        sleepHours: totals['sleep'] ?? 0,
        calorieGoal: result.calorieGoal,
        waterGoal: result.waterGoal,
        sleepGoal: result.sleepGoal,
        metricColors: metricColors,
        showCalories: showCalories,
        showWater: showWater,
        showSleep: showSleep,
        onConfirm: () => Navigator.pop(context),
        openedFromCalendar: true,
      ),
    );
  }

  static Future<void> showFullSummary(
    BuildContext context, {
    required DateTime date,
  }) async {
    final result = await fetchGoalsAndTotals(date);
    final totals = result.totals;

    final metricColors = {
      'calories': getGoalStatus(type: 'calories', intake: totals['calories'] ?? 0, goal: result.calorieGoal).color,
      'water': getGoalStatus(type: 'water', intake: totals['water'] ?? 0, goal: result.waterGoal).color,
      'sleep': getGoalStatus(type: 'sleep', intake: totals['sleep'] ?? 0, goal: result.sleepGoal).color,
    };

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DailySummarySheet(
        isForToday: isSameDay(date, DateTime.now()),
        selectedDate: date,
        calorieIntake: totals['calories'] ?? 0,
        waterIntake: totals['water'] ?? 0,
        sleepHours: totals['sleep'] ?? 0,
        calorieGoal: result.calorieGoal,
        waterGoal: result.waterGoal,
        sleepGoal: result.sleepGoal,
        metricColors: metricColors,
        showCalories: true,
        showWater: true,
        showSleep: true,
        onAddFood: () {
          Navigator.pop(context);
          navigateWithNavBar(
            context,
            AddFoodScreen(mealType: "Breakfast", selectedDate: date),
            initialIndex: 2,
          );
        },
        onAddWater: () {
          Navigator.pop(context);
          navigateWithNavBar(
            context,
            WaterSleepLoggerScreen(type: 'water', selectedDate: date),
            initialIndex: 2,
          );
        },
        onAddSleep: () {
          Navigator.pop(context);
          navigateWithNavBar(
            context,
            WaterSleepLoggerScreen(type: 'sleep', selectedDate: date),
            initialIndex: 2,
          );
        },
        onConfirm: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Log completed for the day!")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

  final missingFood = showCalories && calorieIntake <= 0;
  final missingWater = showWater && waterIntake <= 0;
  final missingSleep = showSleep && sleepHours <= 0;

  final List<String> warnings = [];

  if (missingFood) {
    warnings.add("• You haven’t logged any food today. Logging meals helps track calorie balance.");
  }
  if (missingWater) {
    warnings.add("• You haven’t logged your water intake. Hydration supports energy and digestion.");
  }
  if (missingSleep) {
    warnings.add("• Sleep not logged. Sleep is crucial for recovery and focus.");
  }

  final hasAllData = !missingFood && !missingWater && !missingSleep;

  return DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.5,
    maxChildSize: 0.85,
    minChildSize: 0.35,
    builder: (_, scrollController) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Text(
            "Daily Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          if (showCalories)
            _buildGoalTile("Calories", calorieIntake.toDouble(), calorieGoal.toDouble(), "kcal"),
          if (showWater)
            _buildGoalTile("Water", waterIntake.toDouble(), waterGoal.toDouble(), "ml"),
          if (showSleep)
            _buildGoalTile("Sleep", sleepHours.toDouble(), sleepGoal.toDouble(), "hrs", decimals: 1),

          const SizedBox(height: 24),

          if (openedFromCalendar) ...[
            ElevatedButton.icon(
              onPressed: () async {
              navigateWithNavBar(
                context,
                NutritionScreen(
                  selectedDate: selectedDate,
                  openedFromCalendar: true,
                ),
                initialIndex: 2,
              );
            },   
            icon: const Icon(Icons.arrow_forward),
            label: const Text("View Full Day"),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          ] else ...[
            if (hasAllData) ...[
              const Text(
                "Well done! 😊",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Great job today! Logging your meals, water, and sleep helps you track progress and build healthy habits.",
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Text(
                "Bonus Tip 💡",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                warnings.join("\n\n"),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Complete Log"),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ]

        ],
      ),
    ),
  );
}

  Widget _buildGoalTile(String label, double logged, double goal, String unit, {int decimals = 0}) {
    final color = metricColors[label.toLowerCase()] ?? Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Logged", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("${formatNumber(logged, decimals: decimals)} $unit",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Goal", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("${formatNumber(goal, decimals: decimals)} $unit",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ],
          ),
        ],
      ),
    );
  }
}
