import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showIcon = true,

  });

  final String title;
  final String subtitle;
  final bool showIcon;

@override
Widget build(BuildContext context) {
final color = Theme.of(context).colorScheme.primary;

return Column(
crossAxisAlignment:
showIcon ? CrossAxisAlignment.center : CrossAxisAlignment.start,
children: [
if (showIcon) ...[
Container(
width: 76,
height: 76,
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(25),
),
child: const Icon(
Icons.edit_calendar_rounded,
size: 38,
color: Colors.white,
),
),
const SizedBox(height: 20),
],
Text(
title,
textAlign: showIcon ? TextAlign.center : TextAlign.start,
style: const TextStyle(
fontSize: 25,
fontWeight: FontWeight.w800,
color: Color(0xFF2A1033),
),
),
const SizedBox(height: 8),
Text(
subtitle,
textAlign: showIcon ? TextAlign.center : TextAlign.start,
style: const TextStyle(fontSize: 14, color: Color(0xFF7D8799)),
),
],
);
}
}