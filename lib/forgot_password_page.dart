import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'shell_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController _email;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  Future<void> _sendLink() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _sent = false;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        // Same message as success, so strangers can't find out who has an account.
        setState(() => _sent = true);
      } else if (e.code == 'invalid-email') {
        setState(() => _error = 'That email address doesn\'t look right.');
      } else if (e.code == 'too-many-requests') {
        setState(() => _error = 'Too many attempts. Try again in a minute.');
      } else if (e.code == 'network-request-failed') {
        setState(() => _error = 'No internet connection.');
      } else {
        setState(() => _error = e.message ?? 'Something went wrong.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset your password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: CircleTile(label: 'DC', selected: true, size: 64)),
          const SizedBox(height: 20),
          const Text(
            'Enter the email you signed up with. We\'ll send you a link to '
            'create a new password.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'Email', border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_sent) ...[
            const SizedBox(height: 12),
            const Text(
              'If an account exists for that email, a reset link is on its way. '
              'Check your inbox (and spam folder), open the link and choose a new password.',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _sendLink,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_sent ? 'Send again' : 'Send reset link'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to log in'),
          ),
        ],
      ),
    );
  }
}
