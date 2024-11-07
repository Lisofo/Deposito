import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool disabled;
  final Clip clip;
  final double? tamano;

  const CustomButton({super.key, 
    required this.text,
    required this.onPressed,
    this.disabled = false,
    this.clip = Clip.none,
    this.tamano,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ElevatedButton(
      clipBehavior: clip,
      onPressed: disabled ? null : onPressed,
      style: ButtonStyle(
          backgroundColor: disabled
              ? const WidgetStatePropertyAll(Colors.grey)
              : const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(10),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(50), right: Radius.circular(50))))),
      child: Text(text,
          style: TextStyle(
            fontSize: tamano,
            color:  colors.primary,
            fontWeight: FontWeight.bold,
          )),
          
    );
  }
}
