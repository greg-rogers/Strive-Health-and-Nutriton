import 'package:flutter/material.dart';
import 'package:flutter_testing/helpers/goal_utils.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/nutrition_service.dart';
import '../helpers/formatting_utils.dart';
import '../widgets/daily_summary.dart';

class NutritionCalendarScreen extends StatefulWidget {
  const NutritionCalendarScreen({super.key});

  @override
  State<NutritionCalendarScreen> createState() => _NutritionCalendarScreenState();
}

class _NutritionCalendarScreenState extends State<NutritionCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool showCalories = true;
  bool showWater = true;
  bool showSleep = true;
  bool _isLoading = true;

  final Set<String> _loadedMonths = {};
  final Map<String, Map<String, num>> _summaryCache = {};
  final Map<String, Color> dayColors = {};

  num calorieGoal = 2500;
  num waterGoal = 2000;
  num sleepGoal = 8;

  @override
  void initState() {
    super.initState();
    _loadGoalsAndMonth(_focusedDay);
  }

  Future<void> _loadGoalsAndMonth(DateTime month) async {
    setState(() => _isLoading = true);

    final goals = await fetchGoalsAndTotals(month);
    calorieGoal = goals.calorieGoal;
    waterGoal = goals.waterGoal;
    sleepGoal = goals.sleepGoal;


    final monthsToPreload = [
      DateTime(month.year, month.month - 1),
      month,
      DateTime(month.year, month.month + 1),
    ];

    for (final m in monthsToPreload) {
      await _loadMonthData(m);
    }

    _recalculateDayColors();
    setState(() => _isLoading = false);
  }

  Future<void> _loadMonthData(DateTime month) async {
    final key = "${month.year}-${month.month}";
    if (_loadedMonths.contains(key)) return;

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final summaries = await NutritionService.getSummaryInRange(start, end);

    summaries.forEach((dateStr, data) {
      _summaryCache[dateStr] = data;
    });

    _loadedMonths.add(key);
  }

  void _recalculateDayColors() {
    final updatedColors = <String, Color>{};

    _summaryCache.forEach((dateStr, data) {
      int met = 0, total = 0;

      if (showCalories) {
        total++;
        final result = getGoalStatus(
          intake: data['calories'] ?? 0,
          goal: calorieGoal,
          type: 'calories',
        );
        if (result.goalMet) met++;
      }

      if (showWater) {
        total++;
        final result = getGoalStatus(
          intake: data['water'] ?? 0,
          goal: waterGoal,
          type: 'water',
        );
        if (result.goalMet) met++;
      }

      if (showSleep) {
        total++;
        final result = getGoalStatus(
          intake: data['sleep'] ?? 0,
          goal: sleepGoal,
          type: 'sleep',
        );
        if (result.goalMet) met++;
      }

      updatedColors[dateStr] = total == 0
          ? Colors.grey
          : (met == total
              ? Colors.green
              : (met == 0 ? Colors.red : Colors.orange));
    });

    setState(() {
      dayColors
        ..clear()
        ..addAll(updatedColors);
    });
  }


  void _onFilterChanged(String type, bool value) {
    setState(() {
      if (type == 'calories') showCalories = value;
      if (type == 'water') showWater = value;
      if (type == 'sleep') showSleep = value;
    });
    _recalculateDayColors();
  }

  void _onMonthChanged(DateTime newFocused) {
    setState(() => _focusedDay = newFocused);
    _loadMonthData(newFocused).then((_) => _recalculateDayColors());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nutrition Calendar")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Wrap(
                    spacing: 10,
                    children: [
                      FilterChip(
                        label: const Text("Calories"),
                        selected: showCalories,
                        onSelected: (val) => _onFilterChanged("calories", val),
                      ),
                      FilterChip(
                        label: const Text("Water"),
                        selected: showWater,
                        onSelected: (val) => _onFilterChanged("water", val),
                      ),
                      FilterChip(
                        label: const Text("Sleep"),
                        selected: showSleep,
                        onSelected: (val) => _onFilterChanged("sleep", val),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month, 
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },                    
                    selectedDayPredicate: (_) => false,
                    onPageChanged: _onMonthChanged,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                      DailySummarySheet.showFilteredSummary(
                        context,
                        date: selected,
                        showCalories: showCalories,
                        showWater: showWater,
                        showSleep: showSleep,
                      );
                    },

                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: true,
                      markersAlignment: Alignment.bottomCenter,
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, _) {
                        final dateStr = getFirestoreDateKey(day);
                        final color = dayColors[dateStr];
                        final isTapped = isSameDay(day, _selectedDay);

                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color ?? Colors.transparent,
                            shape: BoxShape.circle,
                            border: isTapped
                            ? Border.all(color: Colors.black, width: 2.5) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        );
                      },
                     todayBuilder: (context, day, _) {
                      final dateStr = getFirestoreDateKey(day);
                      final color = dayColors[dateStr];
                      final isSelected = isSameDay(day, _selectedDay);

                      final shouldShowBorder = _selectedDay == null || isSelected;

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color ?? Colors.transparent,
                          shape: BoxShape.circle,
                          border: shouldShowBorder
                              ? Border.all(color: Colors.black, width: 2.5)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      );
                    },


                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
