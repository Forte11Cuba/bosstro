import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';

/// The boxed field a secret key is pasted or typed into (DS-CMP-11, after
/// ../app's `PasteField`), hidden by default with a show / hide toggle.
///
/// Every state is set here (DS-CMP-19). Hidden, it is one line — Flutter
/// obscures single-line fields only; shown, it wraps so the whole key can be
/// checked. Suggestions, autocorrect and personalised learning are off: a
/// keyboard must never learn a key. With [canReveal] off there is no toggle:
/// the key stays obscured, so it can be neither read back nor selected and
/// copied (a chat key, phase 5c).
class SecretField extends StatefulWidget {
  const SecretField({
    super.key,
    required this.controller,
    required this.hint,
    required this.showLabel,
    required this.hideLabel,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.canReveal = true,
  });

  final TextEditingController controller;
  final String hint;

  /// Tooltips of the visibility toggle (DS-CMP-7).
  final String showLabel;
  final String hideLabel;

  /// Shown under the field, which turns its border to the danger ink.
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Whether the show / hide toggle is offered.
  final bool canReveal;

  @override
  State<SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<SecretField> {
  bool _visible = false;

  static const _textStyle = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 13,
    height: 1.45,
  );

  @override
  Widget build(BuildContext context) {
    final book = ShellPalette.of(context);
    final pal = SettingsPalette.of(context);
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.cta),
      borderSide: BorderSide(color: color),
    );

    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      minLines: 1,
      maxLines: _visible ? 3 : 1,
      cursorColor: book.lime,
      style: _textStyle.copyWith(color: book.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: pal.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: outline(pal.fieldBorder),
        enabledBorder: outline(pal.fieldBorder),
        focusedBorder: outline(pal.fieldFocusBorder),
        errorBorder: outline(book.dangerText),
        focusedErrorBorder: outline(book.dangerText),
        hintText: widget.hint,
        hintStyle: _textStyle.copyWith(color: pal.placeholder),
        errorText: widget.errorText,
        errorMaxLines: 3,
        errorStyle: TextStyle(fontSize: 12, color: book.dangerText),
        suffixIcon:
            !widget.canReveal
                ? null
                : IconButton(
                  tooltip: _visible ? widget.hideLabel : widget.showLabel,
                  icon: Icon(
                    _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: book.textSecondary,
                  ),
                  onPressed: () => setState(() => _visible = !_visible),
                ),
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
