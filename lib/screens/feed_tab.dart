import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add intl to pubspec.yaml for date formatting

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  // Helper to calculate "2 mins ago"
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final DateTime dateTime = timestamp.toDate();
    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 7) return DateFormat.yMMMd().format(dateTime);
    if (diff.inDays >= 1) return "${diff.inDays}d ago";
    if (diff.inHours >= 1) return "${diff.inHours}h ago";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "TravelMate",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black), // Paper plane icon
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No posts yet. Be the first to travel!"));
          }

          return ListView.separated(
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              var post = snapshot.data!.docs[index];
              return _buildPostCard(post, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(QueryDocumentSnapshot post, BuildContext context) {
    // Safely get data
    Map<String, dynamic> data = post.data() as Map<String, dynamic>;

    String userName = data['user_name'] ?? 'Traveler';
    String userPic = data['user_profile_pic'] ?? '';
    String location = data['location'] ?? 'Unknown Location';
    String caption = data['caption'] ?? '';
    List<dynamic> images = data['image_list'] ?? [];
    int rating = data['rating'] ?? 0;

    // Default stats (Hardcoded for now as per screenshot "999")
    // In real app, you would read these from DB array lengths
    int likes = 999;
    int comments = 999;
    int shares = 999;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header (User info)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: userPic.isNotEmpty ? NetworkImage(userPic) : null,
                  child: userPic.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(
                          _getTimeAgo(data['created_at']),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // 2. Caption
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),

          const SizedBox(height: 8),

          // 3. Post Image
          if (images.isNotEmpty)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Image.network(
                images[0], // Showing first image for feed preview
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
              ),
            ),

          const SizedBox(height: 12),

          // 4. Action Row (Rating | Comment | Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Rating
                const Icon(Icons.star_border, size: 24),
                const SizedBox(width: 5),
                Text(
                  "$rating/5", // Showing the rating the user gave
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(width: 20),

                // Comments
                const Icon(Icons.chat_bubble_outline, size: 22),
                const SizedBox(width: 5),
                Text("$comments"),

                const Spacer(),

                // Share
                const Icon(Icons.share_outlined, size: 22),
                const SizedBox(width: 5),
                Text("$shares"),
              ],
            ),
          ),

          // Optional: Divider line
          const SizedBox(height: 8),
          Divider(color: Colors.grey[100], thickness: 5),
        ],
      ),
    );
  }
}