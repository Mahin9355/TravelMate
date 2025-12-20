import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'feed_screen.dart';


class VisitedDistrictsScreen extends StatefulWidget {
  final String homeDistrict;

  const VisitedDistrictsScreen({super.key, required this.homeDistrict});

  @override
  State<VisitedDistrictsScreen> createState() => _VisitedDistrictsScreenState();
}

class _VisitedDistrictsScreenState extends State<VisitedDistrictsScreen> {
  bool _isSaving = false;

  // A Set to store unique selected districts
  final Set<String> _selectedDistricts = {};

  // List of all 64 Districts of Bangladesh
  final List<String> _allDistricts = [
    'Bagerhat', 'Bandarban', 'Barguna', 'Barishal', 'Bhola', 'Bogura', 'Brahmanbaria',
    'Chandpur', 'Chattogram', 'Chuadanga', 'Cox\'s Bazar', 'Cumilla', 'Dhaka', 'Dinajpur',
    'Faridpur', 'Feni', 'Gaibandha', 'Gazipur', 'Gopalganj', 'Habiganj', 'Jamalpur',
    'Jashore', 'Jhalokati', 'Jhenaidah', 'Joypurhat', 'Khagrachhari', 'Khulna', 'Kishoreganj',
    'Kurigram', 'Kushtia', 'Lakshmipur', 'Lalmonirhat', 'Madaripur', 'Magura', 'Manikganj',
    'Meherpur', 'Moulvibazar', 'Munshiganj', 'Mymensingh', 'Naogaon', 'Narail', 'Narayanganj',
    'Narsingdi', 'Natore', 'Netrokona', 'Nilphamari', 'Noakhali', 'Pabna', 'Panchagarh',
    'Patuakhali', 'Pirojpur', 'Rajbari', 'Rajshahi', 'Rangamati', 'Rangpur', 'Satkhira',
    'Shariatpur', 'Sherpur', 'Sirajganj', 'Sunamganj', 'Sylhet', 'Tangail', 'Thakurgaon'
  ];

  @override
  void initState() {
    super.initState();
    // Logic: Auto-select the home district passed from registration
    // We normalize the case to ensure it matches the list (Title Case)
    String normalizedHome = _normalizeString(widget.homeDistrict);

    // Check if the home district is in our valid list (fuzzy match)
    for (String district in _allDistricts) {
      if (district.toLowerCase() == normalizedHome.toLowerCase()) {
        _selectedDistricts.add(district);
        break;
      }
    }

    // If user typed a custom district not in list, we add it anyway
    if (_selectedDistricts.isEmpty && widget.homeDistrict.isNotEmpty) {
      _selectedDistricts.add(widget.homeDistrict);
    }
  }

  String _normalizeString(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update the 'visited_district' field in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'visited_district': _selectedDistricts.toList(),
        });

        if (mounted) {
          // Navigate to main app
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FeedPage()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Where have you been?"),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Header instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            width: double.infinity,
            child: Text(
              "Select the districts you have visited.\nYour home district (${widget.homeDistrict}) is selected by default.",
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ),

          // The Chip List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8.0, // gap between adjacent chips
                runSpacing: 8.0, // gap between lines
                children: _allDistricts.map((district) {
                  final bool isSelected = _selectedDistricts.contains(district);
                  // Check if this specific chip is the home district
                  final bool isHome = district.toLowerCase() == widget.homeDistrict.toLowerCase();

                  return FilterChip(
                    label: Text(district),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedDistricts.add(district);
                        } else {
                          // Prevent deselecting home district? (Optional logic)
                          // For now, allow them to deselect if they want.
                          _selectedDistricts.remove(district);
                        }
                      });
                    },
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue[900] : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    // Visual cue for Home district
                    avatar: isHome ? const Icon(Icons.home, size: 16, color: Colors.blue) : null,
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Finish Setup (${_selectedDistricts.length} selected)",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}