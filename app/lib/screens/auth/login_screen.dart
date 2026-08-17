import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false;
  String _error = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _error = 'Login failed. Check email and password!';
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name!');
      return;
    }
    if (_dobController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your date of birth!');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user details to Firestore!
      final userId = credential.user?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dob': _dobController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Registration failed. Try again!';
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Text(
              'Digital Lifelines',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your life is playing... are you recording?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Name field (only for register)
            if (_isRegisterMode) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),

            // DOB field (only for register)
            if (_isRegisterMode) ...[
              TextField(
                controller: _dobController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'DD/MM/YYYY',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error message
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 8),

            // Loading or buttons
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRegisterMode ? _register : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isRegisterMode ? 'Register' : 'Login',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                    _error = '';
                  });
                },
                child: Text(
                  _isRegisterMode
                      ? 'Already have account? Login'
                      : 'No account? Register here',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}