import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons.dart';
import '../theme.dart';
import '../tokens.dart';

/// Labelled text field with the app's states (focus, error, disabled) and an
/// optional show/hide toggle for passwords.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.icon,
    this.password = false,
    this.showPasswordLabel,
    this.hidePasswordLabel,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.textDirection,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? icon;
  final bool password;
  final String? showPasswordLabel;
  final String? hidePasswordLabel;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;

  /// Force LTR for emails, codes and amounts inside Arabic screens.
  final TextDirection? textDirection;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.password && _hidden,
      enableSuggestions: !widget.password,
      autocorrect: !widget.password,
      keyboardType: widget.password ? TextInputType.visiblePassword : widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      maxLength: widget.maxLength,
      textDirection: widget.textDirection,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        helperMaxLines: 3,
        errorText: widget.errorText,
        errorMaxLines: 3,
        counterText: '',
        prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20),
        suffixIcon: widget.password
            ? IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                tooltip: _hidden ? widget.showPasswordLabel : widget.hidePasswordLabel,
                icon: Icon(_hidden ? AppIcons.show : AppIcons.hide, size: 20, color: colors.textMuted),
              )
            : null,
        constraints: const BoxConstraints(minHeight: Sizes.input),
      ),
    );
  }
}
