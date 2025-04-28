import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/formatting_utils.dart';
import '../services/nutrition_service.dart';
import '../services/streak_service.dart';


class WaterSleepLoggerScreen extends StatefulWidget {
  final String type; // "water" or "sleep"
  final DateTime selectedDate;

  const WaterSleepLoggerScreen({
    super.key,
    required this.type,
    required this.selectedDate,
  });

  @override
  State<WaterSleepLoggerScreen> createState() => _WaterSleepLoggerScreenState();
}

class _WaterSleepLoggerScreenState extends State<WaterSleepLoggerScreen> {
  late int incrementStep;
  late int value;
  late String unit;
  late IconData icon;

  final _controller = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    if (widget.type == 'sleep') {
      incrementStep = 1;
      unit = 'hrs';
      icon = Icons.bedtime;
    } else {
      incrementStep = 100;
      unit = 'ml';
      icon = Icons.water_drop;
    }

    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    final totals = await NutritionService.getDailyTotals(getFirestoreDateKey(widget.selectedDate));
    final current = (totals[widget.type] ?? 0).round();
    setState(() {
      value = current;
      _controller.text = value.toString();
      isLoading = false;
    });
  }

  void _updateValue(int delta) {
    setState(() {
      value = (value + delta).clamp(0, 9999);
      _controller.text = value.toString();
    });
  }

  void _onCustomChange(String input) {
    final parsed = int.tryParse(input);
    if (parsed != null) {
      setState(() => value = parsed.clamp(0, 9999));
    }
  }

  Future<void> _saveValue() async {
    await NutritionService.logDailyMetric(
      dateStr: getFirestoreDateKey(widget.selectedDate),
      field: widget.type,
      value: value,
    );
    
    await StreakService.incrementNutritionStreak(widget.selectedDate);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log ${widget.type == "sleep" ? "Sleep" : "Water"}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(icon, size: 80, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    widget.type == 'sleep' ? 'Sleep' : 'Water',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _updateValue(-incrementStep),
                        iconSize: 40,
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _controller,
                          onChanged: _onCustomChange,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            suffixText: unit,
                            suffixStyle: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _updateValue(incrementStep),
                        iconSize: 40,
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveValue,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
