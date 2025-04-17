import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Logger'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today_rounded),
            onPressed: () => NutritionScreen(),
          ),
        ],
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
              Text(DateFormat('EEEE, MMM d').format(today), style: const TextStyle(fontSize: 16)),
              IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () {}),
            ],
          ),

          const SizedBox(height: 20),

          // Calories Overview
          _buildCaloriesCard(),

          const SizedBox(height: 20),

          // Meal Sections
          _buildMealSection(context, "Breakfast"),
          _buildMealSection(context, "Lunch"),
          _buildMealSection(context, "Dinner"),
          _buildMealSection(context, "Extras"),
          _buildMealSection(context, "Water"),
          _buildMealSection(context, "Sleep"),

          const SizedBox(height: 30),

          // Complete + Bottom Buttons
          ElevatedButton(
            onPressed: () {},
            child: const Text("Complete Log"),
          ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text("Nutrients Remaining", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutrientColumn(label: "Carbs", value: "120g"),
                _NutrientColumn(label: "Fat", value: "50g"),
                _NutrientColumn(label: "Protein", value: "100g"),
                _NutrientColumn(label: "Calories", value: "1,500"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, String meal) {
    return Card(
      child: ExpansionTile(
        title: Text(meal),
        children: [
          ListTile(
            title: const Text("No items added"),
            trailing: TextButton(
              onPressed: () {
                // Navigate to food search screen
              },
              child: const Text("Add Food"),
            ),
          )
        ],
      ),
    );
  }
}

class _NutrientColumn extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
