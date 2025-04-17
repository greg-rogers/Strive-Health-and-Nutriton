import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import 'notifications.dart';
import '../helpers/navigation_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
 
  void _openProfile() {
    navigateWithNavBar(context, const ProfileScreen(), initialIndex: 0);
  }

  void _openNotifications() async {
  navigateWithNavBar(context, const NotificationsScreen(), initialIndex: 0);
}

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Strive', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        actions: [
          if (currentUser != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('notifications')
                  .where('seen', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unseenCount = snapshot.data?.docs.length ?? 0;

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: _openNotifications,
                    ),
                    if (unseenCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Text(
                            unseenCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: const Center(
        child: Text("🏠 Home", style: TextStyle(fontSize: 22)),
      ),
    );
  }
}
