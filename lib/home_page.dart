import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'chat_view.dart'; 
import 'helpers.dart'; 
import 'notification_service.dart';
import 'shell_widgets.dart';
import 'sidebar.dart'; 
import 'theme.dart';

// the home screen is now the REAL app. Everything comes from Cloud
// Firestore, so all signed-in users share the same circles, topics, messages,
// resources and meetings, and a new user sees the whole history.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _notifications = NotificationService();
  StreamSubscription<RemoteMessage>? _msgSub;

  late final Stream<DocumentSnapshot<Json>> _userStream = _db
      .collection('users')
      .doc(_uid)
      .snapshots();
  late final Stream<QuerySnapshot<Json>> _circlesStream = _db
      .collection('circles')
      .orderBy('createdAt')
      .snapshots();

  String? _circleId; // the selected circle
  String? _topicId; // the open topic (wide screens only)
  String _topicName = '';
  String _username = 'You';

  @override
  void initState() {
    super.initState();
    _notifications.init(_uid);
    _msgSub = _notifications.foregroundMessages.listen((message) {
      if (!mounted) return;
      final n = message.notification;
      _snack(n?.title ?? n?.body ?? 'New notification');
    });
    _ensureDefaultCircle();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // The very first user creates the default "DevCircle" circle; after that it
  // already exists for everyone.
  Future<void> _ensureDefaultCircle() async {
    try {
      final ref = _db.collection('circles').doc('devcircle');
      if ((await ref.get()).exists) return;
      await ref.set({
        'name': 'DevCircle',
        'tag': 'DC',
        'subtitle': 'Software engineering students',
        'createdBy': _uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Could not create default circle: $e');
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      _snack('Something went wrong. Please try again.');
    }
  }

  DocumentReference<Json> get _circleRef =>
      _db.collection('circles').doc(_circleId);

  Future<void> _addCircle() async {
    final r = await askFields(context, 'New circle', ['Circle name']);
    final name = r?.first ?? '';
    if (name.isEmpty) return;
    final id = slugOf(name);
    if (id.isEmpty) return _snack('Use letters or numbers in the name');
    await _guard(() async {
      final ref = _db.collection('circles').doc(id);
      if ((await ref.get()).exists) return _snack('That circle already exists');
      await ref.set({
        'name': name,
        'tag': initialsOf(name),
        'subtitle': 'Software engineering students',
        'createdBy': _uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted)
        setState(() {
          _circleId = id;
          _topicId = null;
        });
    });
  }

  Future<void> _addTopic() async {
    final r = await askFields(context, 'New topic', ['Topic name']);
    final name = r?.first ?? '';
    if (name.isEmpty) return;
    final id = slugOf(name);
    if (id.isEmpty) return _snack('Use letters or numbers in the name');
    await _guard(() async {
      final ref = _circleRef.collection('topics').doc(id);
      if ((await ref.get()).exists) return _snack('That topic already exists');
      await ref.set({
        'name': name,
        'createdBy': _uid,
        'createdByName': _username,
        'createdAt': FieldValue.serverTimestamp(),
        'messageCount': 0,
      });
    });
  }

  Future<void> _addResource() async {
    final r = await askFields(context, 'Share a resource', ['Title', 'Link']);
    if (r == null || r[0].isEmpty || r[1].isEmpty) return;
    await _guard(() async {
      await _circleRef.collection('resources').add({
        'title': r[0],
        'link': r[1],
        'createdBy': _uid,
        'createdByName': _username,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _addMeeting() async {
    final r = await askFields(context, 'New meeting', [
      'Topic',
      'Meeting link',
    ]);
    if (r == null || r[0].isEmpty) return;
    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final when = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await _guard(() async {
      await _circleRef.collection('meetings').add({
        'topic': r[0],
        'link': r[1],
        'when': Timestamp.fromDate(when),
        'createdBy': _uid,
        'createdByName': _username,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  void _openTopic(String id, String name, bool wide) {
    if (wide) {
      setState(() {
        _topicId = id;
        _topicName = name;
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          circleId: _circleId!,
          topicId: id,
          topicName: name,
          uid: _uid,
          username: _username,
        ),
      ),
    );
  }

  // Send a "create a new password" email to the signed-in user
  Future<void> _resetPassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    final messenger = ScaffoldMessenger.of(context);
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not send the email.')),
      );
    }
  }

  Widget _settingsMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Settings',
      icon: const Icon(Icons.tune, color: AppColors.muted),
      onSelected: (value) {
        if (value == 'reset') _resetPassword();
        if (value == 'logout') FirebaseAuth.instance.signOut();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'reset', child: Text('Change password')),
        PopupMenuItem(value: 'logout', child: Text('Log out')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1) who am I (username + email type), live from users/{uid}
    return StreamBuilder<DocumentSnapshot<Json>>(
      stream: _userStream,
      builder: (context, userSnap) {
        final data = userSnap.data?.data();
        final email = FirebaseAuth.instance.currentUser?.email;
        _username =
            (data?['username'] as String?) ?? email?.split('@').first ?? 'You';
        final type = data?['emailType'];
        final subtitle = type == 'student'
            ? 'Student email'
            : type == 'personal'
            ? 'Personal email'
            : 'Signed in';

        // 2) the shared circles, live from Firestore
        return StreamBuilder<QuerySnapshot<Json>>(
          stream: _circlesStream,
          builder: (context, circleSnap) {
            final docs = circleSnap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Scaffold(
                backgroundColor: AppColors.rail,
                body: Center(
                  child: Text(
                    circleSnap.hasError
                        ? 'Could not load DevCircle. Check your internet and the Firestore rules.'
                        : 'Setting up DevCircle...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              );
            }
            var selected = docs.indexWhere((d) => d.id == _circleId);
            if (selected < 0) selected = 0;
            final circle = docs[selected];
            _circleId = circle.id;

            return Scaffold(
              backgroundColor: AppColors.rail,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // wide screens (web / desktop): chat opens beside the sidebar
                    final wide = constraints.maxWidth >= 700;
                    final sidebar = CircleSidebar(
                      key: ValueKey(circle.id),
                      uid: _uid,
                      circleId: circle.id,
                      circle: circle.data(),
                      selectedTopicId: wide ? _topicId : null,
                      username: _username,
                      subtitle: subtitle,
                      settings: _settingsMenu(),
                      onOpenTopic: (id, name) => _openTopic(id, name, wide),
                      onAddTopic: _addTopic,
                      onAddResource: _addResource,
                      onAddMeeting: _addMeeting,
                    );
                    return Row(
                      children: [
                        ServerRail(
                          tags: [
                            for (final d in docs)
                              (d.data()['tag'] as String?) ??
                                  initialsOf(
                                    (d.data()['name'] as String?) ?? '?',
                                  ),
                          ],
                          selected: selected,
                          onSelect: (i) => setState(() {
                            _circleId = docs[i].id;
                            _topicId = null;
                          }),
                          onAdd: _addCircle,
                        ),
                        if (wide)
                          SizedBox(width: 300, child: sidebar)
                        else
                          Expanded(child: sidebar),
                        if (wide)
                          Expanded(
                            child: Container(
                              color: AppColors.chatBg,
                              child: _topicId == null
                                  ? const Center(
                                      child: Text(
                                        'Pick a topic to start chatting',
                                        style: TextStyle(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: AppColors.divider,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            '# $_topicName',
                                            style: const TextStyle(
                                              color: AppColors.text,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ChatView(
                                            key: ValueKey(
                                              '${circle.id}/$_topicId',
                                            ),
                                            circleId: circle.id,
                                            topicId: _topicId!,
                                            topicName: _topicName,
                                            uid: _uid,
                                            username: _username,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
