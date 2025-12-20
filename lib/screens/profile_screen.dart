import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default values
  String _name = "Loading...";
  String _profilePic = "";
  String _bio = "";
  String _travelLevel = "Novice Traveler";
  double _rating = 0.0;
  int _visitedCount = 0;
  List<dynamic> _followers = [];
  List<dynamic> _following = [];

  // Colors from your screenshot
  final Color _darkBlue = const Color(0xFF0D1B2A); // Background
  final Color _cyanAccent = const Color(0xFF00E5FF); // Buttons/Badge

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _name = data['name'] ?? "Traveler";
          _profilePic = data['profile_pic'] ?? "";
          _bio = data['bio'] ?? "";
          _rating = (data['user_rating'] ?? 0.0).toDouble();
          _followers = data['followers'] ?? [];
          _following = data['following'] ?? [];
          List visited = data['visited_district'] ?? [];
          _visitedCount = visited.length;

          // Simple logic for Travel Level based on visited count
          if (_visitedCount > 50) {
            _travelLevel = "Globetrotter";
          } else if (_visitedCount > 20) {
            _travelLevel = "Adventurer";
          } else {
            _travelLevel = "Novice Traveler";
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBlue, // Dark background for top half
      appBar: AppBar(
        backgroundColor: _darkBlue,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. PROFILE HEADER
            Center(
              child: Column(
                children: [
                  // Profile Image with White Border
                  Container(
                    padding: const EdgeInsets.all(4), // Border width
                    decoration: const BoxDecoration(
                      color: Colors.white24, // Faint outer glow
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey,
                      backgroundImage: _profilePic.isNotEmpty
                          ? NetworkImage(_profilePic)
                          : null,
                      child: _profilePic.isEmpty
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Name and Rating Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _cyanAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.black),
                            const SizedBox(width: 2),
                            Text(
                              _rating.toString(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  // Travel Level
                  Text(
                    _travelLevel,
                    style: TextStyle(
                        color: _cyanAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      _bio.isNotEmpty ? _bio : "Travel isn't always about running away...",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 2. STATS ROW (Posts, Followers, Following)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn("Posts", "109"), // Placeholder or fetch real post count
                _buildStatColumn("Followers", _followers.length.toString()),
                _buildStatColumn("Following", _following.length.toString()),
              ],
            ),

            const SizedBox(height: 25),

            // 3. ACTION BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Navigate to Edit Profile
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                        // When we come back, refresh the data on this screen
                        _fetchUserData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyanAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyanAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Share", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. VISITED DISTRICTS HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0xFF152638), // Slightly lighter blue strip
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$_visitedCount Districts visited",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),

            // 5. POSTS GRID (White Background section)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(4),
              child: StreamBuilder(
                stream: _firestore
                    .collection('posts')
                    .where('user_id', isEqualTo: _auth.currentUser?.uid) // Only show MY posts
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  // If no posts yet, show empty state
                  if (snapshot.data!.docs.isEmpty) {
                    return const SizedBox(
                        height: 200,
                        child: Center(child: Text("No posts yet."))
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true, // Vital for inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 0.8, // Taller items for image + text
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var post = snapshot.data!.docs[index];
                      String imageUrl = (post['image_list'] as List).isNotEmpty
                          ? post['image_list'][0]
                          : '';
                      String location = post['location'] ?? "Unknown";

                      return Column(
                        children: [
                          // Circular Image Style from screenshot
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(color: Colors.orange, width: 2), // Orange ring
                              ),
                            ),
                          ),
                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Stats
  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Icon(label == "Posts" ? Icons.edit_square :
        label == "Followers" ? Icons.person_outline : Icons.people_outline,
            color: Colors.white70, size: 20),
        const SizedBox(height: 5),
        Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}