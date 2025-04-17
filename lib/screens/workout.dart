import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sessioneditor.dart';
import '../helpers/navigation_helper.dart';


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
    await navigateWithNavBar(
      context,
      SessionEditorScreen(
        date: selectedDate,
        sessionId: sessionId,
      ),
      initialIndex: 1   
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
              SizedBox(width: 16), 
              FloatingActionButton.extended(
                heroTag: "publish",
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Confirm Publish"),
                      content: Text("Are you sure you want to publish this day’s workout to your feed?"),
                      actions: [
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        ElevatedButton(
                          child: Text("Publish"),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Workout published!")),
                    );
                    if (confirmed == true) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final userId = user.uid;

                      // Get sessions for selected day
                      final sessionsSnap = await FirebaseFirestore.instance
                          .collection('workouts')
                          .doc(userId)
                          .collection('sessions')
                          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(selectedDate))
                          .get();

                      for (var sessionDoc in sessionsSnap.docs) {
                        final sessionData = sessionDoc.data();

                        // Fetch exercises for this session
                        final exercisesSnap = await sessionDoc.reference.collection('exercises').get();
                        final exercises = exercisesSnap.docs.map((e) => e.data()).toList();

                        // Add to global feed
                        await FirebaseFirestore.instance.collection('feed').add({
                          'userId': user.uid,
                          'sessionName': sessionData['name'],
                          'duration': sessionData['duration'],
                          'date': sessionData['date'],
                          'exercises': exercises,
                          'publishedAt': FieldValue.serverTimestamp(),

                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Workout published to feed ✅")),
                      );
                    }
                  }
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
