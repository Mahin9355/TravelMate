import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userProfilePic; // <--- NEW FIELD
  final String text;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfilePic,
    required this.text,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'User',
      // Fetch profile pic, default to empty string if missing
      userProfilePic: data['user_profile_pic'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}