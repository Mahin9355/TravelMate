import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _imageLinkController = TextEditingController();

  // Stores the list of image URLs added by the user
  final List<String> _imageUrls = [];

  // Rating state (1 to 5)
  int _selectedRating = 0;

  bool _isLoading = false;

  // User data placeholders
  String _userName = "Loading...";
  String _userProfilePic = "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? "User";
          _userProfilePic = userDoc['profile_pic'] ?? _userProfilePic;
        });
      }
    }
  }

  void _addImageLink() {
    String url = _imageLinkController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _imageUrls.add(url);
        _imageLinkController.clear();
      });
    }
  }

  Future<void> _submitPost() async {
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one image link.")));
      return;
    }
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a location.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('posts').add({
          'user_id': user.uid,
          'user_name': _userName,
          'user_profile_pic': _userProfilePic,
          'image_list': _imageUrls,
          'caption': _captionController.text.trim(),
          'location': _locationController.text.trim(),
          'tagged_people': _tagController.text.trim().split(','), // Simple comma separated list
          'rating': _selectedRating,
          'created_at': FieldValue.serverTimestamp(),
          'likes': [],
        });

        if (mounted) {
          Navigator.pop(context); // Go back to Feed
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post created successfully!")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create post", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Info Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(_userProfilePic),
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

            // 2. Image Preview & Link Input Area
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[100],
              child: _imageUrls.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.image, size: 50, color: Colors.grey),
                    Text("No images added yet"),
                  ],
                ),
              )
                  : PageView.builder(
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    _imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
                  );
                },
              ),
            ),

            // Dots Indicator (Only if images exist)
            if (_imageUrls.length > 1)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _imageUrls.map((url) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black, // Active/Inactive logic can be added here
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Link Input Field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _imageLinkController,
                      decoration: const InputDecoration(
                        hintText: "Paste image link here...",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addImageLink,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),

            // 3. Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildInputRow(Icons.edit_outlined, "Add a caption...", _captionController),
                  const Divider(),
                  _buildInputRow(Icons.location_on_outlined, "Add your location", _locationController),
                  const Divider(),
                  _buildInputRow(Icons.local_offer_outlined, "Tag someone", _tagController),
                  const Divider(),

                  // Rating Row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      children: [
                        const Icon(Icons.star_border, color: Colors.black54),
                        const SizedBox(width: 15),
                        const Text("Rate the place", style: TextStyle(fontSize: 16, color: Colors.black54)),
                        const Spacer(),
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRating = index + 1;
                                });
                              },
                              child: Icon(
                                index < _selectedRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 28,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Post Button
            Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40826D), // Similar to Viridian/Green in screenshot
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "P o s t",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper widget for standard input rows
  Widget _buildInputRow(IconData icon, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}