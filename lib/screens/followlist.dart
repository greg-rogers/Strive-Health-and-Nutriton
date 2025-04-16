import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowListScreen extends StatefulWidget {
  final List<String> userIds;
  final String title;
  final bool allowRemove;

  const FollowListScreen({
    super.key,
    required this.userIds,
    required this.title,
    this.allowRemove = false,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late List<String> filteredUserIds;

  @override
  void initState() {
    super.initState();
    filteredUserIds = [...widget.userIds];
  }

  Future<Map<String, dynamic>> _fetchUser(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  Future<void> _removeUser(String targetUid, bool isFollower) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final currentRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    final targetRef = FirebaseFirestore.instance.collection('users').doc(targetUid);

    if (isFollower) {
    await currentRef.update({
      'followers': FieldValue.arrayRemove([targetUid])
    });
    await targetRef.update({
      'following': FieldValue.arrayRemove([currentUid])
    });
  } else {
    await currentRef.update({
      'following': FieldValue.arrayRemove([targetUid])
    });
    await targetRef.update({
      'followers': FieldValue.arrayRemove([currentUid])
    });
  }

    setState(() {
      filteredUserIds.remove(targetUid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        itemCount: filteredUserIds.length,
        itemBuilder: (context, index) {
          final uid = filteredUserIds[index];

          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchUser(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return ListTile(title: Text("Loading..."));
              final data = snapshot.data!;
              final username = data['username'] ?? 'User';
              final img = data['profileImageUrl'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: img != null ? NetworkImage(img) : null,
                  child: img == null ? const Icon(Icons.person) : null,
                ),
                title: Text(username),
                trailing: widget.allowRemove && uid != currentUid
                    ? TextButton(
                        onPressed: () => _removeUser(uid, widget.title == 'Followers'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("Remove"),
                      )
                    : null,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/publicprofile',
                  arguments: uid,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
