import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'password_field.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const LoginPage({super.key, required this.onSwitch});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _logIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        _showNoAccountDialog();
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        setState(() => _error = 'Email or password is incorrect.');
      } else if (e.code == 'invalid-email') {
        setState(() => _error = 'That email address doesn\'t look right.');
      } else {
        setState(() => _error = e.message ?? 'Something went wrong.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }