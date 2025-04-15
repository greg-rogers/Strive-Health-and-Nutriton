import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      // Check for unique username
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      if (!mounted) return;

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Username already taken")),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      // Create user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': username,
        'email': email,
        'followers': [],
        'following': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign up failed: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: "Username"),
                validator: (val) =>
                    val!.isEmpty ? "Please enter a username" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (val) =>
                    val!.isEmpty ? "Please enter an email" : null,
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
                validator: (val) =>
                    val!.length < 6 ? "Password too short" : null,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signUp,
                      child: Text("Create Account"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
