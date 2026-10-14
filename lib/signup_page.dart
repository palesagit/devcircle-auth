import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'password_field.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const SignUpPage({super.key, required this.onSwitch});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _studentEmail = true;
  bool _loading = false;
  String? _error;

  Future<void> _signUp() async {
    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in every field.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Register with Firebase Auth
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Save the profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'username': username,
        'emailType': _studentEmail ? 'student' : 'personal',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // AuthGate notices the login and shows HomePage automatically.
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _error = 'That email already has an account. Try logging in.';
          case 'weak-password':
            _error = 'Password needs at least 6 characters.';
          case 'invalid-email':
            _error = 'That email address doesn\'t look right.';
          default:
            _error = e.message ?? 'Something went wrong.';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }