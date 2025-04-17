import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'publicprofile.dart';
import '../helpers/navigation_helper.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  String _searchQuery = "";
  List<DocumentSnapshot> _results = [];

  void _searchUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _searchQuery.trim().isEmpty) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: _searchQuery)
        .where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
        .get();

    setState(() {
      _results = snap.docs.where((doc) => doc.id != currentUser.uid).toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Find Users")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(labelText: "Search by username"),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
                _searchUsers();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, index) {
                final user = _results[index];
                final data = user.data() as Map<String, dynamic>;
                final username = data['username'] ?? 'Unknown';
                final profileImageUrl = data['profileImageUrl'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                    child: profileImageUrl == null ? Icon(Icons.person) : null,
                  ),
                  title: Text(username),
                  onTap: () {
                    navigateWithNavBar(
                      context,
                      PublicProfileScreen(userId: user.id),
                      initialIndex: 3
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
