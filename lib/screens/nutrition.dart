import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_testing/helpers/route_aware_mixin.dart';
import 'package:intl/intl.dart';
import 'add_food.dart';
import '../helpers/navigation_helper.dart';
import '../widgets/food_details.dart';
import 'nutrition_details.dart';
import '../helpers/formatting_utils.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with RouteAwareMixin<NutritionScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  void didPopNext() {
    setState(() {}); 
  }

  Stream<Map<String, num>> _nutritionTotalsStream(String dateStr) async* {    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) yield {};

    final meals = ["Breakfast", "Lunch", "Dinner", "Extras"];
    final firestore = FirebaseFirestore.instance;

    yield* firestore
        .collection("users")
        .doc(user?.uid)
        .collection("nutritionLogs")
        .doc(dateStr)
        .snapshots()
        .asyncMap((_) async {
          num totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0, totalFibre = 0;

          for (String meal in meals) {
            final snapshot = await firestore
                .collection("users")
                .doc(user?.uid)
                .collection("nutritionLogs")
                .doc(dateStr)
                .collection(meal)
                .get();

            for (final doc in snapshot.docs) {
              final data = doc.data();

              totalCalories += parseNumber(data['calories']);
              totalProtein  += parseNumber(data['protein']);
              totalCarbs    += parseNumber(data['carbs']);
              totalFat      += parseNumber(data['fat']);
              totalFibre    += parseNumber(data['fibre']);
            }
          }
          return {
            "calories": totalCalories,
            "protein": totalProtein,
            "carbs": totalCarbs,
            "fat": totalFat,
            "fibre": totalFibre,
          };
    });
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
            onPressed: () {},
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
              Text(DateFormat('EEEE, MMM d').format(selectedDate), style: const TextStyle(fontSize: 16)),
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
              navigateWithNavBar(context, const NutritionDetailsScreen(), initialIndex: 2);
            },
            child: _buildCaloriesCard(),),
          const SizedBox(height: 20),
          _buildMealSection(context, "Breakfast"),
          _buildMealSection(context, "Lunch"),
          _buildMealSection(context, "Dinner"),
          _buildMealSection(context, "Extras"),
          _buildMealSection(context, "Water"),
          _buildMealSection(context, "Sleep"),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: () {}, child: const Text("Complete Log")),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(onPressed: () {}, child: const Text("Nutrition")),
              OutlinedButton(onPressed: () {}, child: const Text("Notes")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCaloriesCard() {
    final dateStr = getFirestoreDateKey(selectedDate);
    final int calorieGoal = 2500;

    return StreamBuilder<Map<String, num>>(
      stream: _nutritionTotalsStream(dateStr),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final totals = snapshot.data ?? {};

        num getNum(dynamic val) {
          if (val is num) return val;
          if (val is String) return num.tryParse(val) ?? 0;
          return 0;
        }

        final caloriesConsumed = getNum(totals["calories"]).round();
        final caloriesRemaining = calorieGoal - caloriesConsumed;

        final protein = getNum(totals["protein"]);
        final carbs = getNum(totals["carbs"]);
        final fat = getNum(totals["fat"]);

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
                    _calorieCalcBlock(calorieGoal, "Goal"),
                    const Text("-", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _calorieCalcBlock(caloriesConsumed, "Intake"),
                    const Text("=", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _calorieCalcBlock(caloriesRemaining, "Remaining"),
                  ],
                ),

                const SizedBox(height: 24),
                const Text("Macros", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildMacroBar("Carbs", carbs),
                _buildMacroBar("Fat", fat),
                _buildMacroBar("Protein", protein),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _calorieCalcBlock(int number, String label) {
    return Column(
      children: [
        Text(number.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }


  Widget _buildMacroBar(String label, num value) {
    final double maxVal = 400.0; 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: (value / maxVal).clamp(0.0, 1.0),
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
                    final quantity = num.tryParse(data['quantity'].toString()) ?? 100;
                    final calories = num.tryParse(data['calories'].toString())?.round() ?? 0;

                    return ListTile(
                      title: Text(data['name'] ?? 'Food'),
                      subtitle: Text("Serving size: ${formatNumber(quantity)}g"),
                      trailing: Text(
                        "$calories kcal",
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


