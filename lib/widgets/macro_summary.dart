import 'package:flutter/material.dart';
import '../helpers/formatting_utils.dart';

class MacroSummary extends StatelessWidget {
  final Map<String, dynamic> macros;
  final bool showCalories;
  final bool stackedLayout;

  const MacroSummary({
    super.key,
    required this.macros,
    this.showCalories = true,
    this.stackedLayout = false,
  });

  const MacroSummary.stacked({
    super.key,
    required this.macros,
    this.showCalories = true,
  }) : stackedLayout = true;

  String _getValue(String key) {
    final val = macros[key];
    if (val == null) return '0';
    if (val is num) return formatNumber(val);
    final parsed = num.tryParse(val.toString());
    return parsed == null ? '0' : formatNumber(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final calorieText = Text(
      "${_getValue('calories')} kcal",
      style: const TextStyle(fontWeight: FontWeight.bold),
    );

    final entries = <Widget>[
      if (showCalories) calorieText,
      Text("Protein: ${_getValue('protein')} g"),
      Text("Fat: ${_getValue('fat')} g"),
      Text("Carbs: ${_getValue('carbs')} g"),
      Text("Fibre: ${_getValue('fibre')} g"),
    ];

    return stackedLayout
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: e,
                    ))
                .toList(),
          )
        : Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              if (showCalories) calorieText,
              Text("P: ${_getValue('protein')}g"),
              Text("F: ${_getValue('fat')}g"),
              Text("C: ${_getValue('carbs')}g"),
              Text("Fiber: ${_getValue('fibre')}g"),
            ],
          );
  }
}
