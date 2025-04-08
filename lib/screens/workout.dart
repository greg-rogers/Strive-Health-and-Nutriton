import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> workoutSessions = [];
  bool isWeekView = false;

  @override
  void initState() {
    super.initState();
    _fetchWorkoutSessions();
  }

  Future<void> _fetchWorkoutSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(user.uid)
        .collection('sessions')
        .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(selectedDate))
        .get();

    setState(() {
      workoutSessions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'duration': data['duration'],
          'date': data['date'],
        };
      }).toList();
    });
  }

  bool _hasWorkout(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return workoutSessions.any((s) => s['date'] == dateStr);
  }

  Widget _buildWeekOverview() {
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final sunday = monday.add(Duration(days: 6));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Week: ${DateFormat('dd MMM').format(monday)} - ${DateFormat('dd MMM').format(sunday)}",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = DateFormat('yyyy-MM-dd').format(day) ==
                  DateFormat('yyyy-MM-dd').format(selectedDate);

              return ListTile(
                tileColor: isSelected ? Colors.blue[50] : null,
                title: Text(DateFormat('EEEE, MMM d').format(day)),
                trailing: _hasWorkout(day) ? Icon(Icons.fitness_center, size: 18, color: Colors.blue) : null,
                onTap: () {
                  setState(() {
                    selectedDate = day;
                    isWeekView = false;
                  });
                  _fetchWorkoutSessions();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _goToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
    });
    _fetchWorkoutSessions();
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
    });
    _fetchWorkoutSessions();
  }

  void _navigateToSessionEditor({String? sessionId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionEditorScreen(
          date: selectedDate,
          sessionId: sessionId,
        ),
      ),
    );
    _fetchWorkoutSessions();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEEE, MMMM d, yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Log'),
        actions: [
          IconButton(
            icon: Icon(isWeekView ? Icons.calendar_view_day : Icons.calendar_view_week),
            onPressed: () => setState(() => isWeekView = !isWeekView),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isWeekView) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: _goToPreviousDay, icon: Icon(Icons.arrow_back_ios)),
                  Text(dateText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _goToNextDay, icon: Icon(Icons.arrow_forward_ios)),
                ],
              ),
              SizedBox(height: 16),
              if (workoutSessions.isEmpty)
                Expanded(child: Center(child: Text("No activity yet")))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: workoutSessions.length,
                    itemBuilder: (context, index) {
                      final session = workoutSessions[index];
                      return ListTile(
                        title: Text(session['name']),
                        subtitle: Text("Duration: ${session['duration']}"),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () => _navigateToSessionEditor(sessionId: session['id']),
                      );
                    },
                  ),
                ),
            ] else ...[
              Expanded(child: _buildWeekOverview())
            ]
          ],
        ),
      ),
      floatingActionButton: isWeekView
        ? null
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 16), // for padding from left
              FloatingActionButton.extended(
                heroTag: "publish",
                onPressed: () {
                  // Future implementation: share/publish logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Publish day tapped")),
                  );
                },
                icon: Icon(Icons.public),
                label: Text("Publish Day"),
                backgroundColor: const Color.fromARGB(158, 44, 222, 5),
              ),
              FloatingActionButton(
                heroTag: "addSession",
                onPressed: () => _navigateToSessionEditor(),
                backgroundColor: Colors.blue,
                child: Icon(Icons.add),
              ),
            ],
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

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
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(user.uid)
        .collection('sessions')
        .doc(widget.sessionId)
        .get();

    final data = doc.data();
    if (data != null) {
      sessionNameController.text = data['name'];
      sessionDurationController.text = data['duration'];

      final exerciseSnap = await FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('exercises')
          .get();

      setState(() {
        exercises = exerciseSnap.docs.map((e) => {
            'exercise': e['exercise'].toString(),
            'weight': e['weight'].toString(),
            'reps': e['reps'].toString(),
          }).toList();
        isLoading = false;
      });
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
      'duration': sessionDurationController.text,
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
                      decoration: InputDecoration(labelText: 'Duration (e.g. 1 hour)'),
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
