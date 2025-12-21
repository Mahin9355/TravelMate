import 'package:flutter/material.dart';
import '../services/firebase_feed_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageLinkController = TextEditingController();

  final List<String> _imageUrls = [];
  bool _isUploading = false;

  // Ratings
  double _overallRating = 3.0;
  double _winterRating = 3.0;
  double _summerRating = 3.0;
  double _fallRating = 3.0;

  void _addImage() {
    if (_imageLinkController.text.isNotEmpty) {
      setState(() {
        _imageUrls.add(_imageLinkController.text.trim());
        _imageLinkController.clear();
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one image link")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await FirebaseFeedService().createPost(
        caption: _captionController.text,
        locationName: _locationController.text,
        imageUrls: _imageUrls,
        ratingOverall: _overallRating,
        ratingWinter: _winterRating,
        ratingSummer: _summerRating,
        ratingFall: _fallRating,
      );
      if (mounted) Navigator.pop(context); // Go back to feed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Post"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _submitPost,
            child: const Text("POST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Caption
              TextFormField(
                controller: _captionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?...",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Caption is required" : null,
              ),
              const SizedBox(height: 20),

              // 2. Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location Name (e.g. Cox's Bazar)",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Location is required" : null,
              ),
              const SizedBox(height: 20),

              // 3. Image Links (Simplified for demo)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _imageLinkController,
                      decoration: const InputDecoration(
                        labelText: "Paste Image URL",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: _addImage, child: const Text("Add")),
                ],
              ),
              // Show added images preview
              if (_imageUrls.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(top: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            Image.network(_imageUrls[index], width: 100, height: 100, fit: BoxFit.cover),
                            Positioned(
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrls.removeAt(index)),
                                child: const Icon(Icons.cancel, color: Colors.red),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 30),
              const Text("Rate this Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _buildRatingSlider("Overall Experience", _overallRating, (val) => setState(() => _overallRating = val)),
              _buildRatingSlider("Winter Vibe", _winterRating, (val) => setState(() => _winterRating = val)),
              _buildRatingSlider("Summer Vibe", _summerRating, (val) => setState(() => _summerRating = val)),
              _buildRatingSlider("Fall Vibe", _fallRating, (val) => setState(() => _fallRating = val)),

              if (_isUploading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSlider(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}