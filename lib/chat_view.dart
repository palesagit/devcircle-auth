//whole file. The live chat for one topic.
// Messages are stored in Firestore, so a new user sees the full history and
// everyone sees new messages the moment they are sent.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';
import 'theme.dart';

// Phone screen: an app bar around the chat
class ChatPage extends StatelessWidget {
  final String circleId;
  final String topicId;
  final String topicName;
  final String uid;
  final String username;
  const ChatPage({
    super.key,
    required this.circleId,
    required this.topicId,
    required this.topicName,
    required this.uid,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('# $topicName')),
      body: ChatView(
        circleId: circleId,
        topicId: topicId,
        topicName: topicName,
        uid: uid,
        username: username,
      ),
    );
  }
}

class ChatView extends StatefulWidget {
  final String circleId;
  final String topicId;
  final String topicName;
  final String uid;
  final String username;
  const ChatView({
    super.key,
    required this.circleId,
    required this.topicId,
    required this.topicName,
    required this.uid,
    required this.username,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _db = FirebaseFirestore.instance;

  late final DocumentReference<Json> _topicRef = _db
      .collection('circles')
      .doc(widget.circleId)
      .collection('topics')
      .doc(widget.topicId);

  // "How many messages has this user seen in this topic" (for unread badges)
  late final DocumentReference<Json> _readRef = _db
      .collection('users')
      .doc(widget.uid)
      .collection('reads')
      .doc('${widget.circleId}_${widget.topicId}');

  StreamSubscription<DocumentSnapshot<Json>>? _sub;
  int _marked = -1;
  int _limit = 100; // show the newest 100 messages, "Load older" adds 100 more
  late Stream<QuerySnapshot<Json>> _messages;
  bool _sending = false;

  Stream<QuerySnapshot<Json>> _query() => _topicRef
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(_limit)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _messages = _query();
    // While this chat is open, everything in it counts as read.
    _sub = _topicRef.snapshots().listen((snap) {
      final count = (snap.data()?['messageCount'] as num?)?.toInt() ?? 0;
      if (count != _marked) {
        _marked = count;
        _readRef.set({'readCount': count}).catchError((_) {});
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      // One batch = both writes succeed together: the message AND the counter.
      final batch = _db.batch();
      batch.set(_topicRef.collection('messages').doc(), {
        'text': text,
        'senderId': widget.uid,
        'senderName': widget.username,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_topicRef, {
        'messageCount': FieldValue.increment(1),
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      _controller.text = text; // give the text back so nothing is lost
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message could not be sent. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _bubble(Json m) {
    final mine = m['senderId'] == widget.uid;
    final ts = m['createdAt'] as Timestamp?;
    final time =
        ts == null ? '' : TimeOfDay.fromDateTime(ts.toDate()).format(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? AppColors.brand : AppColors.selected,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((m['senderName'] as String?) ?? 'someone',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: mine ? Colors.white70 : AppColors.accent)),
            Text((m['text'] as String?) ?? '',
                style: const TextStyle(color: AppColors.text)),
            if (time.isNotEmpty)
              Text(time,
                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Json>>(
            stream: _messages,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(
                    child: Text('Could not load messages.',
                        style: TextStyle(color: AppColors.muted)));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs; // newest first
              if (docs.isEmpty) {
                return const Center(
                    child: Text('No messages yet — say hi!',
                        style: TextStyle(color: AppColors.muted)));
              }
              final hasMore = docs.length >= _limit;
              // reverse: true -> newest message sits at the bottom
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: docs.length + (hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == docs.length) {
                    return TextButton(
                      onPressed: () => setState(() {
                        _limit += 100;
                        _messages = _query();
                      }),
                      child: const Text('Load older messages'),
                    );
                  }
                  return _bubble(docs[i].data());
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Message #${widget.topicName}',
                      filled: true,
                      fillColor: AppColors.selected,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
