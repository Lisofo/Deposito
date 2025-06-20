import 'package:flutter/material.dart';

class CustomSpeedDialChild extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const CustomSpeedDialChild({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: label,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            onPressed: onTap,
            child: Icon(icon, size: 28),
          ),
        ],
      ),
    );
  }
}