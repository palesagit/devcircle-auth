import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

//needed for the background message handler below
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'theme.dart'; 

// runs when a notification arrives while the app is closed/in background.
// It must be a top-level function (not inside a class).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // if Firebase isn't configured yet, show a helpful screen
  // instead of a blank crash.
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    runApp(SetupErrorApp(error: e.toString()));
    return;
  }
  // register the background handler (FCM codelab)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const DevCircleApp());
}

//shown only when Firebase setup is missing
class SetupErrorApp extends StatelessWidget {
  final String error;
  const SetupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Firebase is not set up yet.\n\n'
              'Run `flutterfire configure` in the project folder, then restart.\n\n'
              'Details: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class DevCircleApp extends StatelessWidget {
  const DevCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevCircle',
      debugShowCheckedModeBanner: false,
      // shared dark theme
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

// Shows the app if logged in, otherwise the sign-up / log-in screens.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogin = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomePage();

        void toggle() => setState(() => _showLogin = !_showLogin);
        return _showLogin
            ? LoginPage(onSwitch: toggle)
            : SignUpPage(onSwitch: toggle);
      },
    );
  }
}
