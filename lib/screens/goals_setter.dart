import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/goal_service.dart';
import '../helpers/formatting_utils.dart';

class GoalEditorScreen extends StatefulWidget {
  final String goalType;

  const GoalEditorScreen({super.key, required this.goalType});

  @override
  State<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends State<GoalEditorScreen> {
  final _calorieController = TextEditingController();
  final _carbPercentController = TextEditingController();
  final _proteinPercentController = TextEditingController();
  final _fatPercentController = TextEditingController();
  final _singleGoalController = TextEditingController();


  double calorieGoal = 2500;
  double carbPercent = 50;
  double proteinPercent = 30;
  double fatPercent = 20;
  double singleGoal = 0;

  bool _isLoading = true;
  final List<String> _editOrder = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    if (widget.goalType == 'calorieGoal') {
      calorieGoal = (await GoalService.getCalorieGoal())?.toDouble() ?? 2500;
      carbPercent = (await GoalService.getCarbGoal())?.toDouble() ?? 50;
      proteinPercent = (await GoalService.getProteinGoal())?.toDouble() ?? 30;
      fatPercent = (await GoalService.getFatGoal())?.toDouble() ?? 20;
      _setMacroControllers();
    } else if (widget.goalType == 'waterGoal') {
      singleGoal = (await GoalService.getWaterGoal())?.toDouble() ?? 2000;
    } else if (widget.goalType == 'sleepGoal') {
      singleGoal = (await GoalService.getSleepGoal())?.toDouble() ?? 8;
    }

    _singleGoalController.text = formatNumber(singleGoal);
    setState(() => _isLoading = false);
  }

  void _setMacroControllers() {
    _calorieController.text = formatNumber(calorieGoal);
    _carbPercentController.text = formatNumber(carbPercent, decimals: 1);
    _proteinPercentController.text = formatNumber(proteinPercent, decimals: 1);
    _fatPercentController.text = formatNumber(fatPercent, decimals: 1);
  }

  double _gramsFromPercent(double percent, double calsPerGram) {
    return (percent / 100 * calorieGoal) / calsPerGram;
  }

  void _handleMacroChange(String macroKey, String value) {
    double input = double.tryParse(value) ?? 0;

    if (input > 100) {
      input = 100;
      switch (macroKey) {
        case 'carbs':
          _carbPercentController.text = formatNumber(input, decimals: 1);
          break;
        case 'protein':
          _proteinPercentController.text = formatNumber(input, decimals: 1);
          break;
        case 'fat':
          _fatPercentController.text = formatNumber(input, decimals: 1);
          break;
      }
    }

    if (!_editOrder.contains(macroKey)) {
      _editOrder.add(macroKey);
    }

    if (_editOrder.length == 3) {
      _editOrder.clear();
      _editOrder.add(macroKey);
    }

    double newCarb = carbPercent;
    double newProtein = proteinPercent;
    double newFat = fatPercent;

    switch (macroKey) {
      case 'carbs':
        newCarb = input;
        break;
      case 'protein':
        newProtein = input;
        break;
      case 'fat':
        newFat = input;
        break;
    }

    if (_editOrder.length == 1) {
      final remaining = 100 - input;
      final others = ['carbs', 'protein', 'fat']..remove(macroKey);
      final split = remaining / 2;

      for (var m in others) {
        if (m == 'carbs') newCarb = split;
        if (m == 'protein') newProtein = split;
        if (m == 'fat') newFat = split;
      }
    } else if (_editOrder.length == 2) {
      final locked = _editOrder.sublist(0, 2);
      final unlocked = ['carbs', 'protein', 'fat'].firstWhere((m) => !locked.contains(m));

      double totalLocked = 0;
      if (locked.contains('carbs')) totalLocked += newCarb;
      if (locked.contains('protein')) totalLocked += newProtein;
      if (locked.contains('fat')) totalLocked += newFat;

      final remaining = 100 - totalLocked;
      if (unlocked == 'carbs') newCarb = remaining;
      if (unlocked == 'protein') newProtein = remaining;
      if (unlocked == 'fat') newFat = remaining;
    }

    setState(() {
      carbPercent = newCarb.clamp(0, 100);
      proteinPercent = newProtein.clamp(0, 100);
      fatPercent = newFat.clamp(0, 100);

      if (macroKey != 'carbs') _carbPercentController.text = formatNumber(carbPercent, decimals: 1);
      if (macroKey != 'protein') _proteinPercentController.text = formatNumber(proteinPercent, decimals: 1);
      if (macroKey != 'fat') _fatPercentController.text = formatNumber(fatPercent, decimals: 1);
    });
  }

  Future<void> _handleSave() async {
    if (widget.goalType == 'calorieGoal') {
      final parsedCals = double.tryParse(_calorieController.text);
      if (parsedCals == null || parsedCals <= 0) {
        _showError("Please enter a valid calorie goal");
        return;
      }

      final totalPercent = carbPercent + proteinPercent + fatPercent;
      if ((totalPercent - 100).abs() > 0.1) {
        _showError("Macro percentages must total 100%");
        return;
      }

      await GoalService.setGoal('calorieGoal', calorieGoal);
      await GoalService.setCarbGoal(carbPercent);
      await GoalService.setProteinGoal(proteinPercent);
      await GoalService.setFatGoal(fatPercent);
    } else if (widget.goalType == 'waterGoal') {
      final parsed = double.tryParse(_singleGoalController.text);
      if (parsed != null && parsed > 0) {
        await GoalService.setWaterGoal(parsed);
      }
    } else if (widget.goalType == 'sleepGoal') {
      final parsed = double.tryParse(_singleGoalController.text);
      if (parsed != null && parsed > 0) {
        await GoalService.setSleepGoal(parsed);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Goal updated")));
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _calorieController.dispose();
    _carbPercentController.dispose();
    _proteinPercentController.dispose();
    _fatPercentController.dispose();
    _singleGoalController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCalorie = widget.goalType == 'calorieGoal';
    final isWaterSleep = widget.goalType == 'waterGoal';

    return Scaffold(
      appBar: AppBar(title: Text("Edit ${isCalorie ? "Calorie & Macro" : isWaterSleep ? "Water" : "Sleep"} Goal")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isCalorie) ...[
                  _buildCard("Calorie Goal", "Calories (kcal)", _calorieController, "kcal"),
                  const SizedBox(height: 16),
                  _buildMacroTable(),
                ] else ...[
                  _buildCard(
                    isWaterSleep ? "Water Goal" : "Sleep Goal",
                    isWaterSleep ? "Water (ml)" : "Sleep (hrs)",
                    _singleGoalController, 
                    isWaterSleep ? "ml" : "hrs",
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text("Save"),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(String title, String label, TextEditingController controller, String unit) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(label),
        trailing: SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixText: unit,
              border: InputBorder.none,
            ),
            textAlign: TextAlign.right,
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null && parsed > 0) {
                setState(() {
                  if (widget.goalType == 'calorieGoal') {
                    calorieGoal = parsed;
                  } else {
                    singleGoal = parsed;
                  }
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMacroTable() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const ListTile(title: Text("Macro Goals")),
            _macroRow("Carbohydrates", _carbPercentController, "carbs", 4),
            _macroRow("Protein", _proteinPercentController, "protein", 4),
            _macroRow("Fat", _fatPercentController, "fat", 9),
          ],
        ),
      ),
    );
  }

  Widget _macroRow(String label, TextEditingController controller, String macroKey, double calPerGram) {
    final percent = macroKey == "carbs"
        ? carbPercent
        : macroKey == "protein"
            ? proteinPercent
            : fatPercent;
    final grams = _gramsFromPercent(percent, calPerGram);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              decoration: const InputDecoration(suffixText: "%", isDense: true, border: InputBorder.none),
              onChanged: (val) => _handleMacroChange(macroKey, val),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              "${formatNumber(grams, decimals: 1)}g",
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
