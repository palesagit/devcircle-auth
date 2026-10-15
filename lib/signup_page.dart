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

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your DevCircle account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('What kind of email are you signing up with?'),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Personal Email')),
              ButtonSegment(value: true, label: Text('Student Email')),
            ],
            selected: {_studentEmail},
            onSelectionChanged: (s) => setState(() => _studentEmail = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _username,
            decoration: const InputDecoration(
                labelText: 'Username', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          PasswordField(controller: _password),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _signUp,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create Account'),
          ),
          TextButton(
            onPressed: widget.onSwitch,
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}
