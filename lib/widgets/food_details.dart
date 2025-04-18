import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/formatting_utils.dart';
import 'macro_summary.dart';

class FoodDetailSheet extends StatefulWidget {
  final Map<String, dynamic> foodData;
  final void Function(Map<String, dynamic> adjustedData)? onAdd;
  final bool isEditMode;
  final String? docId;
  final String? mealType;
  final DateTime selectedDate;

  const FoodDetailSheet({
    super.key,
    required this.foodData,
    this.onAdd,
    this.isEditMode = false,
    this.docId,
    this.mealType,
    required this.selectedDate,
  });

  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  double quantity = 100;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    quantity = (widget.foodData['quantity'] ?? 100).toDouble();
    _controller = TextEditingController(text: formatNumber(quantity));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = quantity / 100;

    final adjusted = {
      "name": widget.foodData['name'],
      "calories": (parseNumber(widget.foodData['calories']) * multiplier),
      "protein": (parseNumber(widget.foodData['protein']) * multiplier),
      "fat": (parseNumber(widget.foodData['fat']) * multiplier),
      "carbs": (parseNumber(widget.foodData['carbs']) * multiplier),
      "fibre": (parseNumber(widget.foodData['fibre']) * multiplier),
      "quantity": quantity,
    };

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.foodData['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text("Serving Size (g):", style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                  ],
                  decoration: const InputDecoration(hintText: "e.g. 150 or 32.5"),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed > 0 && parsed <= 2000) {
                      setState(() {
                        quantity = parsed;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text("Nutritional Info", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: MacroSummary.stacked(
              key: ValueKey(adjusted.toString()), 
              macros: adjusted,
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final dateStr = getFirestoreDateKey(widget.selectedDate);
                final user = FirebaseAuth.instance.currentUser;

                if (!widget.isEditMode || widget.docId == null || widget.mealType == null) {
                  widget.onAdd?.call(adjusted);
                } else {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('nutritionLogs')
                      .doc(dateStr)
                      .collection(widget.mealType!)
                      .doc(widget.docId!)
                      .update(adjusted);

                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.uid)
                      .collection("nutritionLogs")
                      .doc(dateStr)
                      .set({"lastUpdated": FieldValue.serverTimestamp()}, SetOptions(merge: true));
                }

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: Text(widget.isEditMode ? "Save Changes" : "Add to Meal"),
            ),
          ),
        ],
      ),
    );
  }
}
