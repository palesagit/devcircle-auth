import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef Json = Map<String, dynamic>; // short name used across the app

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String shortWhen(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  final min = d.minute == 0 ? '' : ':${d.minute.toString().padLeft(2, '0')}';
  final soon = d.difference(DateTime.now()).inDays < 7;
  final day =
      soon ? _weekdays[d.weekday - 1] : '${_months[d.month - 1]} ${d.day}';
  return '$day $h$min $ampm';
}


String slugOf(String name) {
  return name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

Future<void> copyLink(BuildContext context, String link) async {
  await Clipboard.setData(ClipboardData(text: link));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Link copied to clipboard')),
  );
}

Future<List<String>?> askFields(
    BuildContext context, String title, List<String> labels) {
  final controllers = labels.map((_) => TextEditingController()).toList();
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            TextField(
              controller: controllers[i],
              autofocus: i == 0,
              decoration: InputDecoration(labelText: labels[i]),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
              ctx, controllers.map((c) => c.text.trim()).toList()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> showDetails(
    BuildContext context, String title, String details, String link) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(link.isEmpty ? details : '$details\n$link'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        if (link.isNotEmpty)
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              copyLink(context, link);
            },
            child: const Text('Copy link'),
          ),
      ],
    ),
  );
}
