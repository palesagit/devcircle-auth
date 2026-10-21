import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Round / rounded-square tile such as "DC", "JV".
class CircleTile extends StatelessWidget {
  final String label;
  final bool selected;
  final double size;
  final VoidCallback? onTap;
  const CircleTile({
    super.key,
    required this.label,
    this.selected = false,
    this.size = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.selected,
          borderRadius: BorderRadius.circular(selected ? size * 0.33 : size / 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
            color: selected ? AppColors.onAccent : AppColors.text,
          ),
        ),
      ),
    );
  }
}

/// The far-left strip of circles (DC, JV, PY, FL, +).
class ServerRail extends StatelessWidget {
  final List<String> tags;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  const ServerRail({
    super.key,
    required this.tags,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.rail,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (var i = 0; i < tags.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                height: 48,
                child: Stack(
                  children: [
                    // white pill on the left shows which circle is selected
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 4,
                        height: i == selected ? 36 : 0,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.horizontal(right: Radius.circular(4)),
                        ),
                      ),
                    ),
                    Center(
                      child: CircleTile(
                        label: tags[i],
                        selected: i == selected,
                        onTap: () => onSelect(i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i == 0)
              const Center(
                child: SizedBox(
                  width: 32,
                  child: Divider(
                      color: AppColors.divider, thickness: 2, height: 12),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: GestureDetector(
                onTap: onAdd,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CustomPaint(
                    painter: _DashedCirclePainter(),
                    child: const Icon(Icons.add, color: AppColors.accent),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B5AA6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = (Offset.zero & size).deflate(1);
    const dashes = 18;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
          rect, i * 2 * math.pi / dashes, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "DevCircle / Software engineering students" at the top of the sidebar.
class SidebarHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const SidebarHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

/// "TOPICS  +" style title. Leave onAdd null to hide the plus button.
class SectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback? onAdd;
  final Key? addKey;
  const SectionHeader(this.label, {super.key, this.onAdd, this.addKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1)),
          const Spacer(),
          if (onAdd != null)
            IconButton(
              key: addKey,
              tooltip: 'Add',
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20, color: AppColors.muted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            ),
        ],
      ),
    );
  }
}

/// Small grey "#" used in front of topic names.
class HashLeading extends StatelessWidget {
  const HashLeading({super.key});
  @override
  Widget build(BuildContext context) => const Text('#',
      style: TextStyle(
          color: AppColors.muted, fontSize: 20, fontWeight: FontWeight.w500));
}

class SidebarRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final Widget? trailing;
  final bool selected;
  final bool bold;
  final VoidCallback? onTap;
  const SidebarRow({
    super.key,
    required this.leading,
    required this.label,
    this.trailing,
    this.selected = false,
    this.bold = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Row(
              children: [
                SizedBox(width: 22, child: Center(child: leading)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: (selected || bold)
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey italic line shown under a section when it has nothing in it yet.
class EmptyHint extends StatelessWidget {
  final String text;
  const EmptyHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontStyle: FontStyle.italic)),
      );
}

/// Pink bubble with the number of unread messages ("99+" when large).
class UnreadBadge extends StatelessWidget {
  final int count;
  const UnreadBadge(this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.pink, borderRadius: BorderRadius.circular(11)),
      child: Text(count > 99 ? '99+' : '$count',
          style: const TextStyle(
              color: AppColors.onAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

/// Bottom card: avatar, username, email type and a settings button.
class UserFooter extends StatelessWidget {
  final String username;
  final String subtitle;
  final Widget action;
  const UserFooter({
    super.key,
    required this.username,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.pink,
            child: Text(initialsOf(username),
                style: const TextStyle(
                    color: AppColors.onAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }
}
