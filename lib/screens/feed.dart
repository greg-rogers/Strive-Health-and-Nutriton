import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Social Feed"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feed')
            .orderBy('publishedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return Center(child: Text("No posts yet. Be the first! 💪"));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;
              final exercises = List<Map<String, dynamic>>.from(data['exercises'] ?? []);

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['username'] ?? "User",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text("${data['sessionName']} • ${data['duration']}"),
                      Text(data['date'] ?? "", style: TextStyle(color: Colors.grey[600])),
                      Divider(),
                      ...exercises.map((ex) => Text("• ${ex['exercise']} - ${ex['weight']}kg x ${ex['reps']} reps"))
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
