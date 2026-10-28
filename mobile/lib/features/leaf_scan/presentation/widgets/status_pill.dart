import 'package:flutter/material.dart';

/// Borderless rounded pill badge (Provisional amber, Noted grey, red, green).
class StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color text;

  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}
