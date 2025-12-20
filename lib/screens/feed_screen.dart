import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/feed_item_view_model.dart';
import '../services/firebase_feed_service.dart';

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
        title: const Text('TravelMate', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // Use RefreshIndicator for pull-to-refresh capability
      body: RefreshIndicator(
        onRefresh: _fetchInitialFetch,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          // Add 1 extra item count if we are loading (for the spinner at bottom)
          itemCount: _feedItems.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            // If index corresponds to the extra item, show loader
            if (index == _feedItems.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Map data to the card widget
            return PostCard(viewModel: _feedItems[index]);
          },
        ),
      ),
      // BottomNavigationBar omitted for brevity, same as previous answer
    );
  }
}

class PostCard extends StatelessWidget {
  final FeedItemViewModel viewModel;

  const PostCard({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final user = viewModel.user;
    final post = viewModel.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Header ---
          Row(
            children: [
              // Fixed the CircleAvatar issue using CachedNetworkImageProvider
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: CachedNetworkImageProvider(user.profilePicUrl),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 8),
                      // Use timeago package
                      Text(
                        timeago.format(post.timestamp),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  Text(user.locationName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // --- 2. Caption ---
          Text(post.caption, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          // --- 3. Image ---
          if (post.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // Using CachedNetworkImage for better performance in feeds
              child: CachedNetworkImage(
                imageUrl: post.imageUrls.first, // Displaying first image for now
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                    height: 200, color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator())),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          const SizedBox(height: 12),
          // --- 4. Footer Stats ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(Icons.star_border, post.likesCount.toString()),
              _buildActionButton(Icons.chat_bubble_outline, post.commentsCount.toString()),
              _buildActionButton(Icons.share_outlined, post.sharesCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count) {
    // ... (Same implementation as previous response)
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.black87),
        const SizedBox(width: 6),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}