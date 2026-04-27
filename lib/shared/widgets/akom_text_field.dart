import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AkomTextField extends StatelessWidget {
  const AkomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autocorrect;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      autofocus: autofocus,
      focusNode: focusNode,
      enabled: enabled,
      autocorrect: autocorrect,
      textCapitalization: textCapitalization,
      style: AkomTextStyles.bodyLarge.copyWith(color: AkomColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  left: AkomSpacing.md,
                  right: AkomSpacing.sm,
                ),
                child: IconTheme(
                  data: const IconThemeData(
                    color: AkomColors.onSurfaceVariant,
                    size: 20,
                  ),
                  child: prefixIcon!,
                ),
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: AkomSpacing.sm),
                child: IconTheme(
                  data: const IconThemeData(
                    color: AkomColors.onSurfaceVariant,
                    size: 20,
                  ),
                  child: suffixIcon!,
                ),
              )
            : null,
        suffixIconConstraints: suffixIcon != null
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
      ),
    );
  }
}

// Champ dédié aux montants FCFA — clavier numérique, entier positif uniquement
class AkomPriceField extends StatelessWidget {
  const AkomPriceField({
    super.key,
    required this.controller,
    this.label = 'Prix',
    this.errorText,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return AkomTextField(
      controller: controller,
      label: label,
      hint: '0',
      errorText: errorText,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction ?? TextInputAction.next,
      onChanged: onChanged,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      suffixIcon: const Text(
        'FCFA',
        style: TextStyle(
          color: AkomColors.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
