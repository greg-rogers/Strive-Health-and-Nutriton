import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final username = usernameController.text.trim();
    final password = passwordController.text;

    try {
      // 🔍 Get user's email by username
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (!mounted) return;

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Username not found")),
        );
        setState(() => _isLoading = false);
        return;
      }

      final email = userQuery.docs.first['email'];

      // 🔐 Log in with email and password
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
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
                    val!.isEmpty ? "Enter your username" : null,
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
                      onPressed: _loginUser,
                      child: Text("Login"),
                    ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
