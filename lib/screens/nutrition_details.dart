import 'package:flutter/material.dart';

class NutritionDetailsScreen extends StatelessWidget {
  const NutritionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Nutrition"),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Calories"),
              Tab(text: "Macros"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CaloriesTabView(),
            MacrosTabView(),
          ],
        ),
      ),
    );
  }
}

class CaloriesTabView extends StatelessWidget {
  const CaloriesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Calories view "));
  }
}

class MacrosTabView extends StatelessWidget {
  const MacrosTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Macros view"));
  }
}
