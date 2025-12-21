import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/feed_item_view_model.dart';
import '../services/firebase_feed_service.dart';
import '../widgets/post_card.dart';
import 'add_post_screen.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // The service that talks to Firebase
  final FirebaseFeedService _feedService = FirebaseFeedService();
  // The ScrollController detects when we reach the bottom
  final ScrollController _scrollController = ScrollController();

  List<FeedItemViewModel> _feedItems = [];
  bool _isLoading = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialFetch();
    // Add listener for scrolling
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // If we are near the bottom (curr position >= max scroll - 200 pixels buffer)
    // and not currently loading and have more data available
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreData) {
      _fetchMoreData();
    }
  }

  Future<void> _fetchInitialFetch() async {
    setState(() => _isLoading = true);
    _feedService.resetPagination();
    List<FeedItemViewModel> newItems = await _feedService.fetchNextBatch();
    setState(() {
      _feedItems = newItems;
      // If we got fewer items than the limit, we probably hit the end
      if (newItems.length < FirebaseFeedService.postsLimit) {
        _hasMoreData = false;
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchMoreData() async {
    setState(() => _isLoading = true);
    List<FeedItemViewModel> newItems = await _feedService.fetchNextBatch();
    setState(() {
      _feedItems.addAll(newItems);
      if (newItems.isEmpty || newItems.length < FirebaseFeedService.postsLimit) {
        _hasMoreData = false;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      // Use RefreshIndicator for pull-to-refresh capability
      body: RefreshIndicator(
        onRefresh: _fetchInitialFetch,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(4.0),
          // Add 1 extra item count if we are loading (for the spinner at bottom)
          itemCount: _feedItems.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            // If index corresponds to the extra item, show loader
            if (index == _feedItems.length) {
              return const Padding(
                padding: EdgeInsets.all(2.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Map data to the card widget
            return PostCard(viewModel: _feedItems[index]);
          },
        ),
      ),
    );
  }
}