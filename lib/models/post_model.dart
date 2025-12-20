import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String authorId; // The vital link to the UserModel
  final String caption;
  final List<String> imageUrls; // Corresponds to {image_list} in ER
  final DateTime timestamp;
  // We denormalize counts for easy UI access
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.caption,
    required this.imageUrls,
    required this.timestamp,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      authorId: data['authorId'] ?? '',
      caption: data['caption'] ?? '',
      // Safely convert dynamic list to string list
      imageUrls: List<String>.from(data['image_list'] ?? []),
      // Handle Firestore Timestamp conversion
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
    );
  }
}