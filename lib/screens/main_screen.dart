import 'package:flutter/material.dart';
import 'package:travel_mate/screens/create_post_screen.dart'; // Import your create post screen
import 'package:travel_mate/screens/profile_screen.dart';
import 'feed_tab.dart'; // We will create this next

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of tabs
  final List<Widget> _pages = [
    const FeedTab(),              // 0: Home
    const Center(child: Text("Explore Map")), // 1: Explore (Placeholder)
    const Center(child: Text("Add Post")),    // 2: Placeholder (Handled by button)
    const Center(child: Text("Leaderboard")), // 3: Leaderboard (Placeholder)
    const ProfileScreen(),     // 4: Profile (Placeholder)
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // If "Add Post" is tapped, open the CreatePostScreen as a full page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 32), label: "Add"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: "Leaderboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}