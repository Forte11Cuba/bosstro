import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';

/// A boxed text input (DS-CMP-11): the label above, the field with radius 14
/// on the settings field fill, and the error under it in the danger ink. The
/// look of [SecretField], for text that is not secret (a node's public key,
/// a relay address). [mono] sets keys and URLs in the monospace face.
class BoxedField extends StatelessWidget {
  const BoxedField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.mono = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final bool mono;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final book = ShellPalette.of(context);
    final pal = SettingsPalette.of(context);
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.cta),
      borderSide: BorderSide(color: color),
    );
    final textStyle = TextStyle(
      fontFamily: mono ? AppFonts.mono : AppFonts.ui,
      fontSize: 13,
      height: 1.45,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: book.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          cursorColor: book.lime,
          style: textStyle.copyWith(color: book.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: pal.fieldFill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: outline(pal.fieldBorder),
            enabledBorder: outline(pal.fieldBorder),
            focusedBorder: outline(pal.fieldFocusBorder),
            errorBorder: outline(book.dangerText),
            focusedErrorBorder: outline(book.dangerText),
            hintText: hint,
            hintStyle: textStyle.copyWith(color: pal.placeholder),
            errorText: errorText,
            errorMaxLines: 4,
            errorStyle: TextStyle(fontSize: 12, color: book.dangerText),
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
