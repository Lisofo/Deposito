import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class EscanerPDA extends StatelessWidget {
  final Function(String) onScan;
  final FocusNode focusNode;
  final TextEditingController controller;
  final Key? visibilityKey;

  const EscanerPDA({
    super.key,
    required this.onScan,
    required this.focusNode,
    required this.controller,
    this.visibilityKey,
  });

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: visibilityKey ?? const Key('scanner-field-visibility'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0) {
          focusNode.requestFocus();
        }
      },
      child: TextFormField(
        focusNode: focusNode,
        cursorColor: Colors.transparent,
        decoration: const InputDecoration(
          border: UnderlineInputBorder(borderSide: BorderSide.none),
        ),
        style: const TextStyle(color: Colors.transparent),
        autofocus: true,
        keyboardType: TextInputType.none,
        controller: controller,
        onFieldSubmitted: onScan,
      ),
    );
  }
}