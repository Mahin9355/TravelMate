import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String profilePicUrl;
  final String locationName; // From user 'homedistrict' or current location

  UserModel({
    required this.userId,
    required this.name,
    required this.profilePicUrl,
    required this.locationName,
  });

  // Factory constructor to create a UserModel from Firebase data
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? 'Unknown',
      // Provide a default placeholder if image is missing
      profilePicUrl: data['profile_pic'] ?? 'https://placehold.co/100x100.png',
      locationName: data['homedistrict'] ?? 'Unknown Location',
    );
  }
}