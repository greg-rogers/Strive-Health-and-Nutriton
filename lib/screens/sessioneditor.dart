import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class SessionEditorScreen extends StatefulWidget {
  final DateTime date;
  final String? sessionId;

  const SessionEditorScreen({super.key, required this.date, this.sessionId});

  @override
  State<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends State<SessionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController sessionNameController = TextEditingController();
  final TextEditingController sessionDurationController = TextEditingController();
  final TextEditingController exerciseController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  List<Map<String, String>> exercises = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final logger = Logger();
    if (user == null || widget.sessionId == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('sessions')
          .doc(widget.sessionId);

      final doc = await docRef.get();

      if (!doc.exists) {
        logger.w("Session with ID '${widget.sessionId}' not found.");
        setState(() => isLoading = false);
        return;
      }

      final data = doc.data();
      if (data != null) {
        sessionNameController.text = data['name'] ?? '';
        sessionDurationController.text = data['duration'].toString();

        final exerciseSnap = await docRef.collection('exercises').get();

        setState(() {
          exercises = exerciseSnap.docs.map((e) => {
                'exercise': e['exercise'].toString(),
                'weight': e['weight'].toString(),
                'reps': e['reps'].toString(),
              }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      logger.w("Error loading session: $e");
      setState(() => isLoading = false);
    }
  }


  void _addExercise() {
    if (exerciseController.text.isNotEmpty &&
        weightController.text.isNotEmpty &&
        repsController.text.isNotEmpty) {
      setState(() {
        exercises.add({
          'exercise': exerciseController.text,
          'weight': weightController.text,
          'reps': repsController.text,
        });
      });
      exerciseController.clear();
      weightController.clear();
      repsController.clear();
    }
  }

  Future<void> _saveSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sessionData = {
      'name': sessionNameController.text,
      'duration': double.tryParse(sessionDurationController.text.trim()) ?? 0.0,
      'date': DateFormat('yyyy-MM-dd').format(widget.date),
    };

    DocumentReference sessionRef;

    if (widget.sessionId == null) {
      sessionRef = await FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('sessions')
          .add(sessionData);
    } else {
      sessionRef = FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('sessions')
          .doc(widget.sessionId);

      await sessionRef.set(sessionData);
    }

    final exercisesRef = sessionRef.collection('exercises');
    final currentExercises = await exercisesRef.get();
    for (final doc in currentExercises.docs) {
      await doc.reference.delete();
    }
    for (final exercise in exercises) {
      await exercisesRef.add(exercise);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionId == null ? 'New Session' : 'Edit Session'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSession,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: sessionNameController,
                      decoration: InputDecoration(labelText: 'Session Name'),
                    ),
                    TextFormField(
                      controller: sessionDurationController,
                      decoration: InputDecoration(labelText: 'Duration (minutes e.g. 60 minutes)'),
                    ),
                    Divider(),
                    Text("Add Exercise"),
                    TextFormField(
                      controller: exerciseController,
                      decoration: InputDecoration(labelText: 'Exercise'),
                    ),
                    TextFormField(
                      controller: weightController,
                      decoration: InputDecoration(labelText: 'Weight (kg)'),
                    ),
                    TextFormField(
                      controller: repsController,
                      decoration: InputDecoration(labelText: 'Reps'),
                    ),
                    ElevatedButton(
                      onPressed: _addExercise,
                      child: Text("Add Exercise"),
                    ),
                    Divider(),
                    Text("Exercises:"),
                    ...exercises.map((e) => ListTile(
                          title: Text("${e['exercise']} - ${e['weight']}kg x ${e['reps']} reps"),
                        )),
                  ],
                ),
              ),
            ),
    );
  }
}
