import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String locationId;
  final String locationName;
  final String caption;
  final List<String> imageUrls;
  final List<String> tagList;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime timestamp;
  // NEW: To track if the current user liked this post
  final bool isLikedByCurrentUser;

  PostModel({
    required this.postId,
    required this.userId,
    required this.locationId,
    required this.locationName,
    required this.caption,
    required this.imageUrls,
    required this.tagList,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    required this.timestamp,
    // Initialize with false, will be set by service
    this.isLikedByCurrentUser = false,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      userId: data['user_id'] ?? '',
      locationId: data['location_id'] ?? '',
      locationName: data['location_name'] ?? '',
      caption: data['caption'] ?? '',
      imageUrls: List<String>.from(data['image_list'] ?? []),
      tagList: List<String>.from(data['tag_list'] ?? []),
      likesCount: data['likes_count'] ?? 0,
      commentsCount: data['comments_count'] ?? 0,
      sharesCount: data['shares_count'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Helper to create a copy of the post with an updated like state
  PostModel copyWith({bool? isLikedByCurrentUser, int? likesCount}) {
    return PostModel(
      postId: postId,
      userId: userId,
      locationId: locationId,
      locationName: locationName,
      caption: caption,
      imageUrls: imageUrls,
      tagList: tagList,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      timestamp: timestamp,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}