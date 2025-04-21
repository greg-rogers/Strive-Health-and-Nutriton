import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_testing/helpers/goal_utils.dart';
import 'package:flutter_testing/helpers/route_aware_mixin.dart';
import 'package:flutter_testing/screens/add_water_sleep.dart';
import 'package:flutter_testing/screens/nutrition_calendar.dart';
import 'package:flutter_testing/widgets/notes.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_food.dart';
import '../helpers/navigation_helper.dart';
import '../widgets/food_details.dart';
import 'nutrition_details.dart';
import '../helpers/formatting_utils.dart';
import '../widgets/daily_summary.dart';

class NutritionScreen extends StatefulWidget {
  final DateTime? selectedDate; 
  final bool openedFromCalendar;


  const NutritionScreen({super.key, this.selectedDate, this.openedFromCalendar = false,});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with RouteAwareMixin<NutritionScreen> {
late DateTime selectedDate;
late bool openedFromCalendar;


  @override
  void initState() {
    super.initState();
    openedFromCalendar = widget.openedFromCalendar;
    WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      setState(() {
        openedFromCalendar = false;
      });
    }
  });
  
    selectedDate = widget.selectedDate ?? DateTime.now();

  }

  @override
  void didPopNext() {
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Logger'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              navigateWithNavBar(
                context,
                NutritionCalendarScreen(),
                initialIndex: 2,
              );            
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedDate = selectedDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              Text(
                DateFormat('EEEE, MMM d').format(selectedDate),
                style: const TextStyle(fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    selectedDate = selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () {
              navigateWithNavBar(
                context,
                NutritionDetailsScreen(selectedDate: selectedDate),
                initialIndex: 2,
              );
            },
            child: FutureBuilder(
              future: _buildCaloriesCard(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return snapshot.data ?? const SizedBox.shrink();
              },
            ),
          ),

          const SizedBox(height: 20),
          _buildMealSection(context, "Breakfast"),
          _buildMealSection(context, "Lunch"),
          _buildMealSection(context, "Dinner"),
          _buildMealSection(context, "Extras"),
          _buildMealSection(context, "Water"),
          _buildMealSection(context, "Sleep"),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () async {

            if (openedFromCalendar) {
              await DailySummarySheet.showFilteredSummary(
                context,
                date: selectedDate,
                showCalories: true,
                showWater: true,
                showSleep: true,
              );
            } else {
              await DailySummarySheet.show(
                context,
                date: selectedDate,
                isForToday: isSameDay(selectedDate, DateTime.now()),
              );
            }

          },

            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text("Complete Log"),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  navigateWithNavBar(
                  context,
                  NutritionDetailsScreen(selectedDate: selectedDate),
                  initialIndex: 2,
                );                },
                child: const Text("Nutrition"),
              ),
              OutlinedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => NotesBottomSheet(selectedDate: selectedDate),
                  );
                },
                child: const Text("Notes"),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Future<Widget> _buildCaloriesCard() async {
    final result = await fetchGoalsAndTotals(selectedDate);
    final totals = result.totals;

    final caloriesConsumed = (totals["calories"] ?? 0).round();
    final caloriesRemaining = result.calorieGoal - caloriesConsumed;

    final carbs = totals["carbs"] ?? 0;
    final fat = totals["fat"] ?? 0;
    final protein = totals["protein"] ?? 0;

    final carbGoalGrams = result.macroGrams['carbs']!;
    final fatGoalGrams = result.macroGrams['fat']!;
    final proteinGoalGrams = result.macroGrams['protein']!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Calories Remaining", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _calorieCalcBlock(result.calorieGoal, "Goal"),
                const Text("-", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _calorieCalcBlock(caloriesConsumed, "Intake"),
                const Text("=", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _calorieCalcBlock(caloriesRemaining, "Remaining"),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Macros", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildMacroBar("Carbs", carbs, carbGoalGrams),
            _buildMacroBar("Fat", fat, fatGoalGrams),
            _buildMacroBar("Protein", protein, proteinGoalGrams),
          ],
        ),
      ),
    );
  }

  Widget _calorieCalcBlock(num number, String label) {
    return Column(
      children: [
        Text(formatNumber(number), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }


  Widget _buildMacroBar(String label, num value, num goal) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 8),
          Text("${formatNumber(value)}g")
        ],
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, String meal) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final dateStr = getFirestoreDateKey(selectedDate);

    return Card(
      child: ExpansionTile(
        title: Text(meal),
        children: [
          if (meal == "Water" || meal == "Sleep")
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('nutritionLogs')
                  .doc(dateStr)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final value = parseNumber(data[meal.toLowerCase()]);

                if (value == 0) {
                  return ListTile(
                    title: const Text("No data logged"),
                    trailing: TextButton(
                      onPressed: () {
                        navigateWithNavBar(
                          context,
                          WaterSleepLoggerScreen(
                            type: meal.toLowerCase(),
                            selectedDate: selectedDate,
                          ),
                          initialIndex: 2,
                        );
                      },
                      child: Text(meal == "Water" ? "Add Water" : "Add Sleep"),
                    ),
                  );
                }

                return ListTile(
                  title: Text("${formatNumber(value)} ${meal == "Water" ? "ml" : "hrs"}"),
                  trailing: TextButton(
                    onPressed: () {
                      navigateWithNavBar(
                        context,
                        WaterSleepLoggerScreen(
                          type: meal.toLowerCase(),
                          selectedDate: selectedDate,
                        ),
                        initialIndex: 2,
                      );
                    },
                    child: const Text("Edit"),
                  ),
                );
              },
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('nutritionLogs')
                  .doc(dateStr)
                  .collection(meal)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return ListTile(
                    title: const Text("No items added"),
                    trailing: TextButton(
                      onPressed: () {
                        navigateWithNavBar(
                          context,
                          AddFoodScreen(mealType: meal, selectedDate: selectedDate),
                          initialIndex: 2,
                        );
                      },
                      child: const Text("Add Food"),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final quantity = parseNumber(data['quantity']);
                      final calories = parseNumber(data['calories']);

                      return ListTile(
                        title: Text(data['name'] ?? 'Food'),
                        subtitle: Text("Serving size: ${formatNumber(quantity)}g"),
                        trailing: Text(
                          "${formatNumber(calories, decimals: 0)} kcal",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => FoodDetailSheet(
                              foodData: data,
                              isEditMode: true,
                              docId: doc.id,
                              mealType: meal,
                              selectedDate: selectedDate,
                            ),
                          );
                        },
                      );
                    }),
                    ListTile(
                      trailing: TextButton(
                        onPressed: () {
                          navigateWithNavBar(
                            context,
                            AddFoodScreen(mealType: meal, selectedDate: selectedDate),
                            initialIndex: 2,
                          );
                        },
                        child: const Text("Add More"),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

}


