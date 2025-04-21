import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_testing/services/nutrition_service.dart';
import '../helpers/route_aware_mixin.dart';
import '../widgets/food_details.dart';
import '../helpers/formatting_utils.dart';
import 'dart:async';
import '../widgets/macro_summary.dart';

class AddFoodScreen extends StatefulWidget {
  final String mealType;
  final DateTime selectedDate;

  const AddFoodScreen({
    super.key,
    required this.mealType,
    required this.selectedDate,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> with RouteAwareMixin<AddFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void didPopNext() {
    super.didPopNext();
    _searchFoods(_searchController.text);
  }

  void _searchFoods(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);

      final results = await FirebaseFirestore.instance
          .collection('foods')
          .orderBy('name_lower')
          .startAt([query.toLowerCase()])
          .endAt(["${query.toLowerCase()}\uf8ff"])
          .limit(25)
          .get();

      if (mounted) {
        setState(() {
          _searchResults = results.docs;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _logFood(Map<String, dynamic> foodData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateStr = getFirestoreDateKey(widget.selectedDate);

    final logRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('nutritionLogs')
        .doc(dateStr)
        .collection(widget.mealType);

    foodData['date'] = Timestamp.fromDate(widget.selectedDate);

    await logRef.add(foodData);
    await NutritionService.updateCalorieTotal(dateStr);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('nutritionLogs')
        .doc(dateStr)
        .set({"lastUpdated": FieldValue.serverTimestamp()}, SetOptions(merge: true));

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add to ${widget.mealType.capitalize()}")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search foods...",
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults = [];
                          });
                        },
                      )
                    : const Icon(Icons.search),
              ),
              onChanged: _searchFoods,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(child: Text("Start typing to find food"))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (_, index) {
                          final data = _searchResults[index].data() as Map<String, dynamic>;

                          return ListTile(
                            title: Text(data['name']),
                            subtitle:  MacroSummary(macros: data),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => FoodDetailSheet(
                                  foodData: data,
                                  onAdd: (adjustedData) => _logFood(adjustedData),
                                  selectedDate: widget.selectedDate,
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// String extension for title casing
extension StringCasing on String {
  String capitalize() => isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
