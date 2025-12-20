import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feed_screen.dart';
import 'main_screen.dart'; // Ensure this import matches your project structure

class ProfilePictureScreen extends StatefulWidget {
  const ProfilePictureScreen({super.key});

  @override
  State<ProfilePictureScreen> createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _previewUrl;

  // This is the default placeholder if they skip or if the link is broken
  // (This matches the one you used in RegisterScreen)
  final String _defaultPlaceholder = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _updateProfilePic(String url) async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profile_pic': url,
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSkip() {
    // Since we already set a default image in RegisterScreen,
    // skipping just means navigating to Feed without updating anything.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FeedPage()),
    );
  }

  void _onContinue() {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a link or press Skip")),
      );
      return;
    }
    _updateProfilePic(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add a Photo"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Show your face to the community!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Image Preview Circle
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(
                  (_previewUrl != null && _previewUrl!.isNotEmpty)
                      ? _previewUrl!
                      : _defaultPlaceholder
              ),
            ),

            const SizedBox(height: 30),

            // URL Input Field
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                  labelText: "Paste Image Link",
                  hintText: "https://example.com/my-photo.jpg",
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () {
                      // Update preview when user clicks check icon
                      setState(() {
                        _previewUrl = _urlController.text.trim();
                      });
                    },
                  )
              ),
              onChanged: (val) {
                // Optional: Live preview update
                setState(() {
                  _previewUrl = val.trim();
                });
              },
            ),

            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Set Profile Picture"),
              ),
            ),

            const SizedBox(height: 15),

            // Skip Button
            TextButton(
              onPressed: _isLoading ? null : _onSkip,
              child: const Text(
                "Skip for now",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}