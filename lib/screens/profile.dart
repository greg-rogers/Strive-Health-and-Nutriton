import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_testing/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'login.dart';
import 'followlist.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  Map<DateTime, int> _activityMap = {}; 
  bool _isLoading = true;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserProfileAndWorkouts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _fetchUserProfileAndWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final sessionSnap = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(user.uid)
        .collection('sessions')
        .get();

    final activity = <DateTime, int>{};
    for (var doc in sessionSnap.docs) {
      final dateStr = doc['date'];
      final date = DateTime.parse(dateStr);
      final day = DateTime(date.year, date.month, date.day);
      final rawDuration = doc['duration'];
      final duration = (rawDuration is num)
          ? rawDuration.toDouble()
          : double.tryParse(rawDuration.toString()) ?? 0.0;
      activity[day] = ((activity[day] ?? 0) + duration).toInt();
    }

    setState(() {
      _activityMap = activity;
      userData = userDoc.data() ?? {};
      _isLoading = false;
    });
  }

  Future<void> _openFollowList(String title, List<String> ids, bool allowRemove) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userIds: ids,
          title: title,
          allowRemove: allowRemove,
        ),
      ),
    );
    _fetchUserProfileAndWorkouts();
  }


  Future<void> _pickAndUploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final ref = FirebaseStorage.instance.ref().child("profile_pics/${user.uid}/profile.jpg");

    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profileImageUrl': downloadUrl,
    });

    setState(() {
      userData['profileImageUrl'] = downloadUrl;
    });
  }

  Color _getCellColor(DateTime day) {
    final duration = _activityMap[DateTime(day.year, day.month, day.day)] ?? 0;
    if (duration == 0) return Colors.transparent;
    if (duration < 30) return Colors.lightBlue[100]!;
    if (duration < 60) return Colors.blue[300]!;
    if (duration < 120) return Colors.blue[600]!;
    return Colors.blue[900]!;
  }

  Widget _buildHeatMap() {
    return TableCalendar(
      focusedDay: DateTime.now(),
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final color = _getCellColor(day);
          return GestureDetector(
            onTap: () => _showWorkoutDetails(day),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${day.day}', style: const TextStyle(fontSize: 12)),
            ),
          );
        },
      ),
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        isTodayHighlighted: false,
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      availableGestures: AvailableGestures.none,
    );
  }

  void _showWorkoutDetails(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final sessionSnap = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(user.uid)
        .collection('sessions')
        .where('date', isEqualTo: dateStr)
        .get();

    if (!mounted) return;

    if (sessionSnap.docs.isEmpty) {
      showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No workouts for ${DateFormat.yMMMd().format(date)}"),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(DateFormat.yMMMMd().format(date),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...sessionSnap.docs.map((doc) {
                final session = doc.data();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🧱 ${session['name']} — ${session['duration']} hrs"),
                    FutureBuilder<QuerySnapshot>(
                      future: doc.reference.collection('exercises').get(),
                      builder: (context, exerciseSnap) {
                        if (!exerciseSnap.hasData) return const Text("Loading exercises...");
                        final exercises = exerciseSnap.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: exercises.map((e) {
                            final ex = e.data() as Map<String, dynamic>;
                            return Text("• ${ex['exercise']} — ${ex['weight']}kg x ${ex['reps']} reps");
                          }).toList(),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not found. Please log in again.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAndUploadProfileImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: userData['profileImageUrl'] != null
                          ? NetworkImage(userData['profileImageUrl'])
                          : null,
                      child: userData['profileImageUrl'] == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Username: ${userData['username'] ?? user.email}"),
                Text("Email: ${user!.email}"),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final followerIds = List<String>.from(userData['followers'] ?? []);
                         _openFollowList('Followers', followerIds, true);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "Followers: ${userData['followers']?.length ?? 0}",
                          style: TextStyle(
                            color: Colors.blue[800],
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        final followingIds = List<String>.from(userData['following'] ?? []);
                        _openFollowList('Following', followingIds, true);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "Following: ${userData['following']?.length ?? 0}",
                          style: TextStyle(
                            color: Colors.blue[800],
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Workout Activity",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _buildHeatMap(),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                    },
                    icon: Icon(Icons.logout),
                    label: Text("Log Out"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
