import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helpers/route_aware_mixin.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with RouteAwareMixin<NotificationsScreen> {
  bool _markedSeen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_markedSeen) {
      _markAllAsSeen();
      _markedSeen = true;
    }
  }
  @override
  void didPopNext() {
    _markAllAsSeen();
  }

  Future<void> _markAllAsSeen() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .where('seen', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'seen': true});
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Notifications")),
        body: Center(child: Text("You're not logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(child: Text("No notifications yet 📭"));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (_, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final type = data['type'] ?? '';
              final fromUsername = data['fromUsername'] ?? 'Someone';
              final time = (data['timestamp'] as Timestamp).toDate();

              String message;
              if (type == 'like') {
                message = "$fromUsername liked your post";
              } else if (type == 'comment') {
                message = "$fromUsername commented: \"${data['comment']}\"";
              } else if (type == 'follow') {
                message = "$fromUsername started following you";
              } else {
                message = "You have a new notification";
              }

              return ListTile(
                leading: Icon(Icons.notifications),
                title: Text(message),
                subtitle: Text(_formatTimeAgo(time)),
              );
            },
          );
        },
      ),
    );
  }
}
