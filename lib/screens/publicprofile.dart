import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic> userData = {};
  List<String> followers = [];
  List<String> following = [];
  bool isFollowing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = doc.data();

    if (data != null) {
      final fetchedFollowers = List<String>.from(data['followers'] ?? []);
      final fetchedFollowing = List<String>.from(data['following'] ?? []);

      setState(() {
        userData = data;
        followers = fetchedFollowers;
        following = fetchedFollowing;
        isFollowing = followers.contains(currentUser.uid);
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final targetRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    final currentUserDoc = await currentRef.get();
    final username = currentUserDoc.data()?['username'] ?? 'User';

    if (isFollowing) {
      await currentRef.update({
        'following': FieldValue.arrayRemove([widget.userId])
      });
      await targetRef.update({
        'followers': FieldValue.arrayRemove([currentUser.uid])
      });

      setState(() {
        isFollowing = false;
        followers.remove(currentUser.uid);
      });
    } else {
      await currentRef.update({
        'following': FieldValue.arrayUnion([widget.userId])
      });
      await targetRef.update({
        'followers': FieldValue.arrayUnion([currentUser.uid])
      });

      // Send follow notification
      await targetRef.collection('notifications').add({
        'type': 'follow',
        'fromUserId': currentUser.uid,
        'fromUsername': username,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });

      setState(() {
        isFollowing = true;
        followers.add(currentUser.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(userData['username'] ?? "User Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: userData['profileImageUrl'] != null
                  ? NetworkImage(userData['profileImageUrl'])
                  : null,
              child: userData['profileImageUrl'] == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              userData['username'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Followers: ${followers.length}"),
                const SizedBox(width: 16),
                Text("Following: ${following.length}"),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleFollow,
              child: Text(isFollowing ? "Unfollow" : "Follow"),
            ),
          ],
        ),
      ),
    );
  }
}
