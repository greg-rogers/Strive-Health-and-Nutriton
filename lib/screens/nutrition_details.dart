// ignore_for_file: unnecessary_null_comparison

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_testing/helpers/navigation_helper.dart';
import 'package:intl/intl.dart';
import '../widgets/goal_ring.dart';
import 'goals_setter.dart';
import '../helpers/formatting_utils.dart';
import '../helpers/goal_utils.dart';

class NutritionDetailsScreen extends StatefulWidget {

  final DateTime selectedDate;
  const NutritionDetailsScreen({super.key, required this.selectedDate});

  @override
  State<NutritionDetailsScreen> createState() => _NutritionDetailsScreenState();
}

class _NutritionDetailsScreenState extends State<NutritionDetailsScreen>
with SingleTickerProviderStateMixin {

  late DateTime selectedDate;
  late TabController _tabController;

  num calorieGoal = 2500;
  num calorieIntake = 0;
  num waterGoal = 2000;
  num waterIntake = 0;
  num sleepGoal = 8;
  num sleepActual = 0;

  Map<String, num> macroGoals = {};
  Map<String, num> macroTotals = {};
  Map<String, num> macroGrams = {};


  final GlobalKey _chartKey = GlobalKey();
  OverlayEntry? _tooltipOverlay;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    _tabController = TabController(length: 2, vsync: this);
    _loadGoals();
  }

  Future<void> _loadGoals() async {

    final result = await fetchGoalsAndTotals(selectedDate);
    final totals = result.totals;

    setState(() {
      calorieGoal = result.calorieGoal;
      waterGoal = result.waterGoal;
      sleepGoal = result.sleepGoal;
      calorieIntake = totals['calories'] ?? 0;
      waterIntake = totals['water'] ?? 0;
      sleepActual = totals['sleep'] ?? 0;
      macroGoals = result.macroGoals;
      macroTotals = {
        'carbs': totals['carbs'] ?? 0,
        'protein': totals['protein'] ?? 0,
        'fat': totals['fat'] ?? 0,
      };
      macroGrams = result.macroGrams;
      isLoading = false;
    });
  }

  void _changeDay(int direction) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: direction));
      isLoading = true;
    });
    _loadGoals();
  }

  void _openGoalEditor(String goalType) {
    navigateWithNavBar(
      context,
      GoalEditorScreen(goalType: goalType),
      initialIndex: 2,
    ).then((_) => _loadGoals());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Nutrition"),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Calories"),
              Tab(text: "Macros"),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDay(-1),
                  ),
                  Text(
                    DateFormat('EEEE, MMM d').format(selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDay(1),
                  ),
                ],
              ),
            ),
            isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCaloriesTab(),
                        _buildMacrosTab(),
                      ],
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
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
            onTap: () => _openGoalEditor('calorieGoal'),
          ),
          GoalRingWidget(
            title: "Water",
            centreLabel: "${(waterGoal - waterIntake).round()} ml Remaining",
            progress: waterIntake / waterGoal,
            metrics: [
              {"Goal": "${formatNumber(waterGoal)} ml"},
              {"Intake": "${formatNumber(waterIntake)} ml"},
            ],
            metricColors: {
              "Intake": getGoalStatus(type: "water", intake: waterIntake, goal: waterGoal).color,
            },
            onTap: () => _openGoalEditor('waterGoal'),
          ),
          GoalRingWidget(
            title: "Sleep",
            centreLabel: "${(sleepGoal - sleepActual).toStringAsFixed(1)} hrs Remaining",
            progress: sleepActual / sleepGoal,
            metrics: [
              {"Goal": "${formatNumber(sleepGoal, decimals: 1)} h"},
              {"Slept": "${formatNumber(sleepActual, decimals: 1)} h"},
            ],
            metricColors: {
              "Intake": getGoalStatus(type: "sleep", intake: sleepActual, goal: sleepGoal).color,
            },            
            onTap: () => _openGoalEditor('sleepGoal'),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosTab() {
    final macroLabels = ["Carbs", "Protein", "Fat"];

    final macroValues = macroLabels.map((label) {
      return macroTotals[label.toLowerCase()]?.toDouble() ?? 0.0;
    }).toList();

    final macroGoalPercents = macroLabels.map((label) {
      return macroGoals[label.toLowerCase()]?.toDouble() ?? 0.0;
    }).toList();

    final macroGoalGrams = macroLabels.map((label) {
      return macroGrams[label.toLowerCase()]?.toDouble() ?? 0.0;
    }).toList();
    final totalCals = (macroValues[0] * 4 + macroValues[1] * 4 + macroValues[2] * 9).clamp(1, double.infinity);
    final macroCals = [macroValues[0] * 4, macroValues[1] * 4, macroValues[2] * 9];
    final macroPercents = macroCals.map((c) => (c / totalCals).clamp(0.0, 1.0)).toList();

    final macroColors = [Colors.yellow[700]!, Colors.teal[400]!, Colors.red[300]!];

    return GestureDetector(
      onTapDown: (_) => _removeTooltip(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: Container(
                key: _chartKey,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent || response?.touchedSection == null) return;

                        final index = response!.touchedSection!.touchedSectionIndex;
                        if (index < 0 || index >= 3) return;

                        final label = macroLabels[index];
                        final macro = macroValues[index];
                        final cals = macroCals[index];

                        final box = _chartKey.currentContext?.findRenderObject() as RenderBox?;
                        if (box != null) {
                          _showTooltip(
                            context,
                            box.localToGlobal(event.localPosition),
                            _buildTooltipText(label, macro, cals),
                          );
                        }
                      },
                    ),
                    sections: List.generate(3, (i) {
                      return PieChartSectionData(
                        color: macroColors[i],
                        value: macroCals[i],
                        title: "${(macroPercents[i] * 100).round()}%",
                        radius: 60,
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) => _buildLegendItem(macroColors[i], macroLabels[i])),
            ),
            const SizedBox(height: 24),
            ...List.generate(3, (i) => _macroTile(
              macroLabels[i],
              macroValues[i],
              macroPercents[i],
              macroGoalPercents[i],
              macroGoalGrams[i],
              macroColors[i],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _macroTile(String label, double grams, double percent, double goalPercent, double goalGrams, Color color) {
    return GestureDetector(
      onTap: () => _openGoalEditor('calorieGoal'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Consumed", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                "${(percent * 100).toStringAsFixed(1)}% (${formatNumber(grams)}g)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: getGoalStatus(
                    intake: grams,
                    goal: goalGrams,
                    type: label.toLowerCase(),
                  ).color,
                ),
              ),            
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Goal", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("${goalPercent.toStringAsFixed(1)}% (${formatNumber(goalGrams)}g)", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ]),
          ],
        ),
      ),
    );
  }

  String _buildTooltipText(String macro, double grams, double macroCals) {
    return "$macro: ${formatNumber(grams)} g\n${formatCalories(macroCals)} kcal";
  }

  void _showTooltip(BuildContext context, Offset globalPosition, String label) {
    _removeTooltip();
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final localPosition = overlayBox?.globalToLocal(globalPosition);
    if (overlay == null || localPosition == null) return;

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: localPosition.dx - 40,
        top: localPosition.dy - 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
            ),
            child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
    overlay.insert(_tooltipOverlay!);
    Future.delayed(const Duration(seconds: 4), _removeTooltip);
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }
}