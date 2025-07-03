import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duolingo_clone_project/auth_screen/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/level_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const Color greenPrimary = Color(0xFF4CAF50);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // ✅ Save user with default language = German
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailController.text.trim(),
        'xp': 0,
        'streak': 0,
        'language': 'German', // ✅ Default language field
        'lastActive': FieldValue.serverTimestamp(),
      });

      // ✅ Clone levels for the user
      final levelsSnapshot = await FirebaseFirestore.instance.collection('levels').get();
      for (final doc in levelsSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('levels')
            .doc(doc.id)
            .set({
          'isUnlocked': doc['levelNumber'] == 1,
          'levelNumber': doc['levelNumber'],
          'title': doc['title'],
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LevelScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGradient = LinearGradient(
      colors: [Color(0xFFE8F5E9), Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    const greyBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          color: greenPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        cursorColor: Colors.grey,
                        style: const TextStyle(color: Colors.black), // 👈 Black text
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: greyBorder,
                          enabledBorder: greyBorder,
                          focusedBorder: greyBorder,
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) =>
                        v == null || !v.contains('@') ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        cursorColor: Colors.grey,
                        style: const TextStyle(color: Colors.black), // 👈 Black text
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: greyBorder,
                          enabledBorder: greyBorder,
                          focusedBorder: greyBorder,
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (v) =>
                        v == null || v.length < 6 ? 'Min. 6 characters' : null,
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'SIGN UP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignInScreen()),
                          );
                        },
                        child: const Text(
                          "Already have an account? Sign In",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
