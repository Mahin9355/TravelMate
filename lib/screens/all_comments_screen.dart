import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/comment_model.dart';
import '../services/firebase_feed_service.dart';

class AllCommentsScreen extends StatefulWidget {
  final String postId;

  const AllCommentsScreen({super.key, required this.postId});

  @override
  State<AllCommentsScreen> createState() => _AllCommentsScreenState();
}

class _AllCommentsScreenState extends State<AllCommentsScreen> {
  final FirebaseFeedService _feedService = FirebaseFeedService();
  final TextEditingController _commentController = TextEditingController();

  void _handleCommentSubmit(String text) {
    if (text.trim().isNotEmpty) {
      _feedService.addComment(widget.postId, text.trim());
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  // --- NEW: Helper Widget for Safe Profile Pictures ---
  Widget _buildProfileAvatar(String? imageUrl) {
    bool isValidUrl = imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey, // Background color while loading
      ),
      child: isValidUrl
          ? ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Icon(Icons.person, color: Colors.white, size: 20),
          errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white, size: 20),
        ),
      )
          : const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _feedService.getAllComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading comments"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return const Center(child: Text("No comments yet."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Use the new safe avatar builder
                          _buildProfileAvatar(comment.userProfilePic),

                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeago.format(comment.timestamp),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.text, style: const TextStyle(fontSize: 14),)
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, -1))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (val) => _handleCommentSubmit(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _handleCommentSubmit(_commentController.text),
                    icon: const Icon(Icons.send, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}