import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorMessage;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? minLines;
  final bool obscure;
  final bool enabled;
  final TextEditingController? controller;
  final void Function(String?)? onSaved;
  final TextAlign? textAling;
  final String? initialValue;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? mascara;
  final void Function(String)? onFieldSubmitted;
  final int? maxLength;
  final FocusNode? focusNode;
  final Icon? preffixIcon;
  final Widget? suffixIcon;
  final Color? fillColor;
  final Color? prefixIconColor;
  final Color? suffixIconColor;

  const CustomTextFormField({
    super.key,
    this.label,
    this.hint,
    this.errorMessage,
    this.onChanged,
    this.validator,
    this.maxLines,
    this.minLines,
    this.obscure = false,
    this.enabled = true,
    this.controller,
    this.onSaved,
    this.textAling = TextAlign.start,
    this.initialValue,
    this.keyboard,
    this.mascara,
    this.onFieldSubmitted,
    this.maxLength,
    this.focusNode,
    this.preffixIcon,
    this.suffixIcon,
    this.fillColor,
    this.prefixIconColor,
    this.suffixIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(5));

    return TextFormField(
      keyboardType: keyboard,
      initialValue: initialValue,
      textAlign: textAling!,
      enabled: enabled,
      onSaved: onSaved,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      obscureText: obscure,
      decoration: InputDecoration(
        enabledBorder: border,
        focusedBorder: border.copyWith(),
        errorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        isDense: true,
        label: label != null ? Text(label!) : null,
        fillColor: fillColor,
        filled: true,
        prefixIcon: preffixIcon,
        prefixIconColor: prefixIconColor,
        suffixIcon: suffixIcon,
        suffixIconColor: suffixIconColor,
        hintText: hint,
        disabledBorder: border.copyWith(),
        errorText: errorMessage,
      ),
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: mascara,
      maxLength: maxLength,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
    );
  }
}
