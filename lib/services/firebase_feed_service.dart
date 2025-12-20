import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_item_view_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class FirebaseFeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Keep track of the last document fetched for pagination
  DocumentSnapshot? _lastDocument;
  // How many posts to fetch at a time
  static const int postsLimit = 5;

  Future<List<FeedItemViewModel>> fetchNextBatch() async {
    List<FeedItemViewModel> feedItems = [];

    Query q = _db
        .collection('posts')
        .orderBy('timestamp', descending: true) // Newest first
        .limit(postsLimit);

    // If we have fetched before, start after the last one
    if (_lastDocument != null) {
      q = q.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await q.get();

    // If results returned, update the pagination cursor
    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
    } else {
      // No more documents to fetch
      return [];
    }

    // Process the posts and join with user data manually
    for (var doc in querySnapshot.docs) {
      // 1. Convert doc to PostModel
      PostModel post = PostModel.fromFirestore(doc);

      // 2. Fetch the associated user data
      // NOTE: In a real app, consider caching user data so you don't re-fetch the same popular user repeatedly.
      DocumentSnapshot userDoc = await _db.collection('users').doc(post.authorId).get();

      if (userDoc.exists) {
        UserModel user = UserModel.fromFirestore(userDoc);
        // 3. Combine into view model
        feedItems.add(FeedItemViewModel(post: post, user: user));
      }
    }

    return feedItems;
  }

  void resetPagination() {
    _lastDocument = null;
  }
}