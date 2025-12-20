import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_mate/screens/visited_districts_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _homeDistrictController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _homeDistrictController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    String fullName = _fullNameController.text.trim();
    String homeDistrict = _homeDistrictController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // 1. Basic Validation
    if (fullName.isEmpty || homeDistrict.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "All fields are required!");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = "Passwords do not match!");
      return;
    }

    // Validate Home District against list (Optional, but good for UI consistency)
    // For now, we accept whatever they type, but clean it up
    String formattedHomeDistrict = homeDistrict[0].toUpperCase() + homeDistrict.substring(1).toLowerCase();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. Create Authentication User
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 3. Create Firestore Document
        // Note: We initialize 'visited_district' as an empty list here.
        // It will be filled in the NEXT screen.
        await _firestore.collection('users').doc(user.uid).set({
          'name': fullName,
          'email': email,
          'home_district': formattedHomeDistrict,
          'profile_pic': 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
          'bio': 'New to TravelMate!',
          'user_rating': 5, // Matches your screenshot
          'followers': [], // Empty Array
          'following': [], // Empty Array
          'visited_district': [], // Placeholder, will be updated next step
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. Navigate to Visited Districts Page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VisitedDistrictsScreen(
                homeDistrict: formattedHomeDistrict,
              ),
            ),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Registration failed. Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Sign Up"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildTextField(_fullNameController, "Full Name", Icons.person),
              const SizedBox(height: 15),
              _buildTextField(_homeDistrictController, "Home District (e.g. Dhaka)", Icons.location_on),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email", Icons.email, isEmail: true),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Password", Icons.lock, isPassword: true),
              const SizedBox(height: 15),
              _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock_outline, isPassword: true),
              const SizedBox(height: 25),

              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register & Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}