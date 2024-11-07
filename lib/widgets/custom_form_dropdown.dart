import 'package:flutter/material.dart';

class CustomDropdownFormMenu extends StatelessWidget {
  final List<DropdownMenuItem<dynamic>>? items;
  final Function(dynamic)? onChanged;
  final String? hint;
  final String? errorMessage;
  final String? Function(dynamic)? validator;
  final Function(dynamic)? onSaved;
  final Function()? onTap;
  final dynamic value;

  const CustomDropdownFormMenu(
      {super.key, this.items,
      required this.onChanged,
      this.hint,
      this.errorMessage,
      this.validator,
      this.onSaved,
      this.onTap,
      this.value});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(20));

    return DropdownButtonFormField(
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        enabledBorder: border,
        focusedBorder: border.copyWith(),
        errorBorder:
            border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        focusedErrorBorder:
            border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        isDense: true,
        hintText: hint,
        errorText: errorMessage,
      ),
      validator: validator,
      onSaved: onSaved,
      onTap: onTap,
      value: value,
    );
  }
}
