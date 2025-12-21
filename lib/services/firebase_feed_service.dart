import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/feed_item_view_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';

class FirebaseFeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constants
  static const int postsLimit = 10;

  // Pagination State
  DocumentSnapshot? _lastDocument;

  /// 1. Reset Pagination (Call this on pull-to-refresh)
  void resetPagination() {
    _lastDocument = null;
  }

  /// 2. Fetch Next Batch of Posts
  /// Fetches posts, the user who posted them, and checks if YOU liked them.
  Future<List<FeedItemViewModel>> fetchNextBatch() async {
    User? currentUser = _auth.currentUser;

    Query query = _db
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(postsLimit);

    // If we have a last document, start after it (Pagination)
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();

    // If no data, return empty list
    if (snapshot.docs.isEmpty) return [];

    // Save the last doc for next time
    _lastDocument = snapshot.docs.last;

    List<FeedItemViewModel> feedItems = [];

    for (var doc in snapshot.docs) {
      // A. Convert Firestore doc to PostModel
      PostModel post = PostModel.fromFirestore(doc);

      // B. Check if current user liked this post
      bool isLiked = false;
      if (currentUser != null) {
        DocumentSnapshot likeDoc = await _db
            .collection('posts')
            .doc(post.postId)
            .collection('likes')
            .doc(currentUser.uid)
            .get();
        isLiked = likeDoc.exists;
      }

      // Update the post model with the correct like status
      post = post.copyWith(isLikedByCurrentUser: isLiked);

      // C. Fetch the User data for this post
      DocumentSnapshot userDoc = await _db.collection('users').doc(post.userId).get();

      if (userDoc.exists) {
        UserModel user = UserModel.fromFirestore(userDoc);

        // D. Combine into ViewModel
        feedItems.add(FeedItemViewModel(post: post, user: user));
      }
    }

    return feedItems;
  }

  /// 3. Create a New Post
  /// Handles Posts, Locations, and Ratings in one go.
  Future<void> createPost({
    required String caption,
    required String locationName,
    required List<String> imageUrls,
    required double ratingOverall,
    required double ratingWinter,
    required double ratingSummer,
    required double ratingFall,
  }) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    WriteBatch batch = _db.batch();

    // A. Handle Location (Check if exists, else create)
    String locationId;
    final locQuery = await _db.collection('locations')
        .where('location_name', isEqualTo: locationName)
        .limit(1)
        .get();

    if (locQuery.docs.isNotEmpty) {
      locationId = locQuery.docs.first.id;
    } else {
      DocumentReference newLocRef = _db.collection('locations').doc();
      locationId = newLocRef.id;
      batch.set(newLocRef, {
        'location_name': locationName,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    // B. Create Post
    DocumentReference newPostRef = _db.collection('posts').doc();
    batch.set(newPostRef, {
      'user_id': currentUser.uid,
      'location_id': locationId,
      'location_name': locationName, // Stores location name directly for easy display
      'caption': caption,
      'image_list': imageUrls,
      'tag_list': [],
      'likes_count': 0,
      'comments_count': 0,
      'shares_count': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // C. Create Rating linked to Location
    DocumentReference newRatingRef = _db.collection('ratings').doc();
    batch.set(newRatingRef, {
      'location_id': locationId,
      'post_id': newPostRef.id,
      'overall_rating': ratingOverall,
      'winter_rating': ratingWinter,
      'summer_rating': ratingSummer,
      'fall_rating': ratingFall,
    });

    await batch.commit();
  }

  /// 4. Toggle Like (Star Icon)
  Future<void> toggleLike(String postId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    DocumentReference postRef = _db.collection('posts').doc(postId);
    DocumentReference likeRef = postRef.collection('likes').doc(currentUser.uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        // Already liked -> Unlike it
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likes_count': FieldValue.increment(-1)
        });
      } else {
        // Not liked -> Like it
        transaction.set(likeRef, {
          'user_id': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likes_count': FieldValue.increment(1)
        });
      }
    });
  }

  /// 5. Get Recent Comments (For PostCard Preview)
  Stream<List<CommentModel>> getRecentComments(String postId, {int limit = 2}) {
    return _db.collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CommentModel.fromFirestore(doc))
        .toList());
  }

  /// 6. Get ALL Comments (For Full Comments Page)
  Stream<List<CommentModel>> getAllComments(String postId) {
    return _db.collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CommentModel.fromFirestore(doc))
        .toList());
  }

  /// 7. Add a Comment
  /// Saves User Name AND Profile Pic so they appear instantly in the list
  Future<void> addComment(String postId, String text) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Fetch user details to store in comment (Denormalization)
    DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();
    String userName = userDoc.get('name') ?? 'User';
    String userPic = userDoc.get('profile_pic') ?? ''; // Fetch Profile Pic

    DocumentReference postRef = _db.collection('posts').doc(postId);

    await _db.runTransaction((transaction) async {
      DocumentReference commentRef = postRef.collection('comments').doc();

      transaction.set(commentRef, {
        'user_id': currentUser.uid,
        'user_name': userName,
        'user_profile_pic': userPic, // SAVE IT HERE
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      transaction.update(postRef, {
        'comments_count': FieldValue.increment(1)
      });
    });
  }
}