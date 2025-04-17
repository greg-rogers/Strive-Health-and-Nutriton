import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_testing/helpers/route_aware_mixin.dart';
import '../helpers/navigation_helper.dart';
import 'searchusers.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with RouteAwareMixin<FeedScreen> {
  List<String> followingIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowingAndBuildFeed();
  }

  @override
  void didPopNext() {
    _fetchFollowingAndBuildFeed();
  }


  Future<void> _fetchFollowingAndBuildFeed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final following = List<String>.from(userDoc.data()?['following'] ?? []);
    following.add(user.uid);

    setState(() {
      followingIds = following.take(10).toList();
      isLoading = false;
    });
  }

  Future<void> _toggleLike(String postId, List likedBy, String postOwnerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('feed').doc(postId);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final username = userDoc.data()?['username'] ?? 'User';

    final alreadyLiked = likedBy.contains(user.uid);
    await ref.update({
      'likedBy': alreadyLiked
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid]),
    });

    if (!alreadyLiked && postOwnerId != user.uid) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .collection('notifications')
          .add({
        'type': 'like',
        'fromUserId': user.uid,
        'fromUsername': username,
        'postId': postId,
        'timestamp': FieldValue.serverTimestamp(),
        'seen' : false,
      });
    }
  }

  void _showCommentsModal(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentsSheet(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Social Feed"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              navigateWithNavBar(context, const SearchUsersScreen(), initialIndex: 3);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feed')
            .where('userId', whereIn: followingIds)
            .orderBy('publishedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final data = post.data() as Map<String, dynamic>;
              final exercises = List<Map<String, dynamic>>.from(data['exercises'] ?? []);
              final likedBy = List<String>.from(data['likedBy'] ?? []);
              final isLiked = FirebaseAuth.instance.currentUser != null &&
                  likedBy.contains(FirebaseAuth.instance.currentUser!.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
                builder: (context, userSnap) {
                  final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                  final profileImage = userData['profileImageUrl'];
                  final username = userData['username'] ?? 'User';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    profileImage != null ? NetworkImage(profileImage) : null,
                                child: profileImage == null ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(width: 10),
                              Text(username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("${data['sessionName']} • ${data['duration']} hrs"),
                          Text(data['date'] ?? "",
                              style: TextStyle(color: Colors.grey[600])),
                          const Divider(),
                          ...exercises.map((ex) => Text(
                              "• ${ex['exercise']} - ${ex['weight']}kg x ${ex['reps']} reps")),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : null,
                                ),
                                onPressed: () => _toggleLike(
                                  post.id,
                                  likedBy,
                                  data['userId'],
                                ),
                              ),
                              Text("${likedBy.length} likes"),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.comment),
                                onPressed: () => _showCommentsModal(post.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final commentText = _commentController.text.trim();

    // Save the comment
    await FirebaseFirestore.instance
        .collection('feed')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': commentText,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'username': userData['username'] ?? 'User',
      'profileImageUrl': userData['profileImageUrl'] ?? '',
    });

    // Send notification to post owner if not commenting on own post
    final postDoc = await FirebaseFirestore.instance.collection('feed').doc(widget.postId).get();
    final postOwnerId = postDoc.data()?['userId'];

    if (postOwnerId != null && postOwnerId != user.uid) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .collection('notifications')
          .add({
        'type': 'comment',
        'fromUserId': user.uid,
        'fromUsername': userData['username'] ?? 'User',
        'postId': widget.postId,
        'comment': commentText,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const Text("Comments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feed')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data!.docs;

                  if (comments.isEmpty) {
                    return const Center(child: Text("No comments yet."));
                  }

                  return ListView(
                    controller: scrollController,
                    children: comments.map((doc) {
                      final c = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: c['profileImageUrl'] != ''
                              ? NetworkImage(c['profileImageUrl'])
                              : null,
                          child: c['profileImageUrl'] == '' ? const Icon(Icons.person) : null,
                        ),
                        title: Text(c['username']),
                        subtitle: Text(c['text']),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                left: 12,
                right: 12,
                top: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
