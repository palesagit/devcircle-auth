import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'forgot_password_page.dart'; 
import 'password_field.dart';
import 'shell_widgets.dart'; 

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
    // check the fields before calling Firebase
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
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
      //  return 'invalid-credential' for an
      // unknown email, so 'user-not-found' alone is no longer reliable.
      if (e.code == 'user-not-found') {
        _showNoAccountDialog();
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        setState(() => _error =
            'Email or password is incorrect. No account yet? Tap "Sign up" below.');
      
      } else if (e.code == 'too-many-requests') {
        setState(() => _error = 'Too many attempts. Try again in a minute.');
      } else if (e.code == 'network-request-failed') {
        setState(() => _error = 'No internet connection.');
      } else if (e.code == 'invalid-email') {
        setState(() => _error = 'That email address doesn\'t look right.');
      } else {
        setState(() => _error = e.message ?? 'Something went wrong.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  void _showNoAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No account found'),
        content: const Text(
            'We couldn\'t find an account with that email. Would you like to create one?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSwitch(); // go to the sign-up screen
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in to DevCircle')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // brand logo at the top
          const Center(child: CircleTile(label: 'DC', selected: true, size: 64)),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          PasswordField(controller: _password),
          // forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ForgotPasswordPage(initialEmail: _email.text.trim()),
                ),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            // uses the theme's error colour (readable on dark)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _logIn,
            // shows a spinner while logging in (like the sign-up page)
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Log In'),
          ),
          TextButton(
            onPressed: widget.onSwitch,
            child: const Text('Don\'t have an account? Sign up'),
          ),
        ],
      ),
    );
  }
}
