import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/feed_item_view_model.dart';
import '../models/comment_model.dart';
import '../services/firebase_feed_service.dart';
import '../screens/all_comments_screen.dart';

class PostCard extends StatefulWidget {
  final FeedItemViewModel viewModel;

  const PostCard({super.key, required this.viewModel});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirebaseFeedService _feedService = FirebaseFeedService();
  final TextEditingController _commentController = TextEditingController();

  int _currentImageIndex = 0;

  // State for Post Data
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;

  // State for Current User (Viewer)
  String _currentUserPic = "";

  @override
  void initState() {
    super.initState();
    _isLiked = widget.viewModel.post.isLikedByCurrentUser;
    _likesCount = widget.viewModel.post.likesCount;
    _commentsCount = widget.viewModel.post.commentsCount;
    _fetchCurrentUserPic(); // <--- Fetch the viewer's pic
  }

  // Fetch the profile pic of the person CURRENTLY using the app
  void _fetchCurrentUserPic() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Check if it's already in FirebaseAuth (faster)
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        if (mounted) setState(() => _currentUserPic = user.photoURL!);
      } else {
        // 2. Fallback to Firestore if not in Auth
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (mounted && userDoc.exists) {
            setState(() {
              _currentUserPic = userDoc.get('profile_pic') ?? "";
            });
          }
        } catch (e) {
          print("Error fetching user pic: $e");
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel.post != widget.viewModel.post) {
      setState(() {
        _isLiked = widget.viewModel.post.isLikedByCurrentUser;
        _likesCount = widget.viewModel.post.likesCount;
        _commentsCount = widget.viewModel.post.commentsCount;
      });
    }
  }

  void _handleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    await _feedService.toggleLike(widget.viewModel.post.postId);
  }

  void _handleCommentSubmit(String text) {
    if (text.trim().isNotEmpty) {
      _feedService.addComment(widget.viewModel.post.postId, text.trim());
      _commentController.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _commentsCount += 1;
      });
    }
  }

  void _showAllComments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllCommentsScreen(postId: widget.viewModel.post.postId),
      ),
    );
  }

  // --- SAFE AVATAR BUILDER (Fixes the "adhdhoh" crash) ---
  Widget _buildSafeAvatar(String? imageUrl, {double radius = 14}) {
    bool isValidUrl = imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: isValidUrl
          ? ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Icon(Icons.person, size: radius, color: Colors.white),
        ),
      )
          : Icon(Icons.person, size: radius, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.viewModel.user; // The person who POSTED
    final post = widget.viewModel.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER (Post Author) ---
          Row(
            children: [
              _buildSafeAvatar(user.profilePicUrl, radius: 20), // Author's Pic
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW for Name + Time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "•", // Dot separator
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeago.format(post.timestamp, locale: 'en_short'), // '16 min' style
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),

                    // Location below
                    Text(
                      post.locationName.isNotEmpty ? post.locationName : "Unknown Location",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Optional: You can put a "More Options" icon here since the time is gone
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),

          const SizedBox(height: 12),

          // --- CAPTION ---
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                post.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),

          // --- IMAGES ---
          if (post.imageUrls.isNotEmpty) _buildImageSection(post.imageUrls),

          const SizedBox(height: 12),

          // --- ACTIONS ---
          Row(
            children: [
              _buildLikeButton(),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showAllComments(context),
                child: _buildActionButton(Icons.chat_bubble_outline, "$_commentsCount"),
              ),
              const Spacer(),
              _buildActionButton(Icons.share_outlined, "${post.sharesCount}"),
            ],
          ),

          const Divider(height: 24),

          // --- RECENT COMMENTS PREVIEW ---
          StreamBuilder<List<CommentModel>>(
            stream: _feedService.getRecentComments(post.postId, limit: 2),
            builder: (context, snapshot) {
              final comments = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text("No comments yet.", style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                    ),
                  ...comments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        children: [
                          TextSpan(text: "${c.userName} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: c.text),
                        ],
                      ),
                    ),
                  )),
                  if (_commentsCount > 2)
                    GestureDetector(
                      onTap: () => _showAllComments(context),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: Text("View all $_commentsCount comments", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          // --- ADD COMMENT SECTION ---
          Row(
            children: [
              // SHOW CURRENT USER'S PIC HERE
              _buildSafeAvatar(_currentUserPic, radius: 14),

              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "Add a comment...",
                    hintStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20)), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (val) => _handleCommentSubmit(val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for Image Carousel
  Widget _buildImageSection(List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 500, // Maximum height allowed
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrls.first,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            // If the image is taller than 500px, this aligns it to the top/center
            alignment: Alignment.topCenter,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: imageUrls.length,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: imageUrls.asMap().entries.map((entry) {
            return Container(
              width: 8.0, height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == entry.key ? Colors.blue : Colors.grey[300],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper for Like Button
  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: _handleLike,
      child: Row(
        children: [
          Icon(
            _isLiked ? Icons.star : Icons.star_border,
            size: 24,
            color: _isLiked ? Colors.orange : Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(
            "$_likesCount",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.black87),
        const SizedBox(width: 6),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}