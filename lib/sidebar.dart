//The sidebar for one circle. Everything here is read
// LIVE from Cloud Firestore, so every user sees the same topics, resources
// and meetings, including ones created before they signed up.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';
import 'shell_widgets.dart';
import 'theme.dart';

typedef QStream = Stream<QuerySnapshot<Json>>;

class CircleSidebar extends StatefulWidget {
  final String uid;
  final String circleId;
  final Json circle;
  final String? selectedTopicId;
  final String username;
  final String subtitle; // "Student email" / "Personal email"
  final Widget settings; // the settings menu button
  final void Function(String id, String name) onOpenTopic;
  final VoidCallback onAddTopic;
  final VoidCallback onAddResource;
  final VoidCallback onAddMeeting;

  const CircleSidebar({
    super.key,
    required this.uid,
    required this.circleId,
    required this.circle,
    required this.selectedTopicId,
    required this.username,
    required this.subtitle,
    required this.settings,
    required this.onOpenTopic,
    required this.onAddTopic,
    required this.onAddResource,
    required this.onAddMeeting,
  });

  @override
  State<CircleSidebar> createState() => _CircleSidebarState();
}

class _CircleSidebarState extends State<CircleSidebar> {
  late QStream _topics;
  late QStream _resources;
  late QStream _meetings;
  late QStream _reads;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(CircleSidebar old) {
    super.didUpdateWidget(old);
    if (old.circleId != widget.circleId || old.uid != widget.uid) _setup();
  }

  // The streams are created once here (not in build) so they aren't
  // re-subscribed every time the screen redraws.
  void _setup() {
    final db = FirebaseFirestore.instance;
    final base = db.collection('circles').doc(widget.circleId);
    _topics = base.collection('topics').orderBy('createdAt').snapshots();
    _resources = base.collection('resources').orderBy('createdAt').snapshots();
    final cutoff =
        Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6)));
    _meetings = base
        .collection('meetings')
        .where('when', isGreaterThan: cutoff)
        .orderBy('when')
        .snapshots();
    _reads =
        db.collection('users').doc(widget.uid).collection('reads').snapshots();
  }

  // One section: shows "Loading...", an empty hint, or the rows.
  Widget _section(QStream stream, String empty,
      List<Widget> Function(List<QueryDocumentSnapshot<Json>> docs) rows) {
    return StreamBuilder<QuerySnapshot<Json>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return const EmptyHint('Could not load');
        if (!snap.hasData) return const EmptyHint('Loading...');
        final docs = snap.data!.docs;
        if (docs.isEmpty) return EmptyHint(empty);
        return Column(children: rows(docs));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Container(
      color: AppColors.sidebar,
      child: Column(
        children: [
          SidebarHeader(
            title: (w.circle['name'] as String?) ?? 'DevCircle',
            subtitle: (w.circle['subtitle'] as String?) ?? '',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                SectionHeader('TOPICS',
                    onAdd: w.onAddTopic, addKey: const Key('add-topic')),
                // reads = how many messages THIS user has already seen per topic
                StreamBuilder<QuerySnapshot<Json>>(
                  stream: _reads,
                  builder: (context, readSnap) {
                    final reads = <String, int>{
                      for (final d in readSnap.data?.docs ?? [])
                        d.id: (d.data()['readCount'] as num?)?.toInt() ?? 0,
                    };
                    return _section(_topics, 'No topics yet', (docs) {
                      return [
                        for (final d in docs)
                          _topicRow(d, reads['${w.circleId}_${d.id}'] ?? 0),
                      ];
                    });
                  },
                ),
                SectionHeader('RESOURCES',
                    onAdd: w.onAddResource, addKey: const Key('add-resource')),
                _section(_resources, 'No resources yet', (docs) {
                  return [
                    for (final d in docs)
                      SidebarRow(
                        leading: const Icon(Icons.link,
                            size: 18, color: AppColors.muted),
                        label: (d.data()['title'] as String?) ?? 'Resource',
                        onTap: () => showDetails(
                          context,
                          (d.data()['title'] as String?) ?? 'Resource',
                          'Shared by ${d.data()['createdByName'] ?? 'someone'}',
                          (d.data()['link'] as String?) ?? '',
                        ),
                      ),
                  ];
                }),
                SectionHeader('MEETINGS',
                    onAdd: w.onAddMeeting, addKey: const Key('add-meeting')),
                _section(_meetings, 'No meetings scheduled', (docs) {
                  return [
                    for (final d in docs) _meetingRow(d),
                  ];
                }),
              ],
            ),
          ),
          UserFooter(
            username: w.username,
            subtitle: w.subtitle,
            action: w.settings,
          ),
        ],
      ),
    );
  }

  Widget _topicRow(QueryDocumentSnapshot<Json> d, int readCount) {
    final name = (d.data()['name'] as String?) ?? d.id;
    final total = (d.data()['messageCount'] as num?)?.toInt() ?? 0;
    final open = widget.selectedTopicId == d.id;
    // unread = messages that arrived since this user last opened the topic
    final unread = open ? 0 : (total - readCount).clamp(0, 1 << 30).toInt();
    return SidebarRow(
      leading: const HashLeading(),
      label: name,
      bold: unread > 0,
      selected: open,
      trailing: unread > 0 ? UnreadBadge(unread) : null,
      onTap: () => widget.onOpenTopic(d.id, name),
    );
  }

  Widget _meetingRow(QueryDocumentSnapshot<Json> d) {
    final data = d.data();
    final when = (data['when'] as Timestamp).toDate();
    final topic = (data['topic'] as String?) ?? 'Meeting';
    return SidebarRow(
      leading:
          const Icon(Icons.event_outlined, size: 18, color: AppColors.muted),
      label: topic,
      trailing: Text(shortWhen(when),
          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      onTap: () => showDetails(
        context,
        topic,
        '${shortWhen(when)} · set up by ${data['createdByName'] ?? 'someone'}',
        (data['link'] as String?) ?? '',
      ),
    );
  }
}
