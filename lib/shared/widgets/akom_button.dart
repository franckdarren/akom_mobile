import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AkomButtonVariant { primary, secondary, outlined, ghost, danger }

enum AkomButtonSize { small, medium, large }

class AkomButton extends StatelessWidget {
  const AkomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AkomButtonVariant.primary,
    this.size = AkomButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AkomButtonVariant variant;
  final AkomButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveCallback = isLoading ? null : onPressed;

    final child = isLoading
        ? SizedBox(
            width: _loaderSize,
            height: _loaderSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_foregroundColor),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: _iconSize),
                  const SizedBox(width: AkomSpacing.sm),
                  Text(label),
                ],
              )
            : Text(label);

    Widget button;

    switch (variant) {
      case AkomButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AkomColors.primary,
            foregroundColor: AkomColors.onPrimary,
            minimumSize: Size(isFullWidth ? double.infinity : 0, _height),
            padding: _padding,
            textStyle: _textStyle,
            shape: const RoundedRectangleBorder(
              borderRadius: AkomRadius.borderMd,
            ),
            elevation: 0,
          ),
          child: child,
        );

      case AkomButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AkomColors.secondary,
            foregroundColor: Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 0, _height),
            padding: _padding,
            textStyle: _textStyle,
            shape: const RoundedRectangleBorder(
              borderRadius: AkomRadius.borderMd,
            ),
            elevation: 0,
          ),
          child: child,
        );

      case AkomButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveCallback,
          style: OutlinedButton.styleFrom(
            foregroundColor: AkomColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 0, _height),
            padding: _padding,
            textStyle: _textStyle,
            shape: const RoundedRectangleBorder(
              borderRadius: AkomRadius.borderMd,
            ),
            side: const BorderSide(color: AkomColors.primary, width: 1.5),
          ),
          child: child,
        );

      case AkomButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveCallback,
          style: TextButton.styleFrom(
            foregroundColor: AkomColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 0, _height),
            padding: _padding,
            textStyle: _textStyle,
          ),
          child: child,
        );

      case AkomButtonVariant.danger:
        button = ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AkomColors.error,
            foregroundColor: Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 0, _height),
            padding: _padding,
            textStyle: _textStyle,
            shape: const RoundedRectangleBorder(
              borderRadius: AkomRadius.borderMd,
            ),
            elevation: 0,
          ),
          child: child,
        );
    }

    return button;
  }

  double get _height => switch (size) {
        AkomButtonSize.small => 40,
        AkomButtonSize.medium => 52,
        AkomButtonSize.large => 60,
      };

  EdgeInsets get _padding => switch (size) {
        AkomButtonSize.small =>
          const EdgeInsets.symmetric(horizontal: AkomSpacing.md),
        AkomButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: AkomSpacing.lg),
        AkomButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: AkomSpacing.xl),
      };

  TextStyle get _textStyle => switch (size) {
        AkomButtonSize.small => AkomTextStyles.bodyMedium
            .copyWith(fontWeight: FontWeight.w600),
        AkomButtonSize.medium => AkomTextStyles.labelLarge,
        AkomButtonSize.large =>
          AkomTextStyles.labelLarge.copyWith(fontSize: 16),
      };

  double get _iconSize => switch (size) {
        AkomButtonSize.small => 16,
        AkomButtonSize.medium => 18,
        AkomButtonSize.large => 20,
      };

  double get _loaderSize => switch (size) {
        AkomButtonSize.small => 16,
        AkomButtonSize.medium => 20,
        AkomButtonSize.large => 24,
      };

  Color get _foregroundColor => switch (variant) {
        AkomButtonVariant.primary => AkomColors.onPrimary,
        AkomButtonVariant.secondary => Colors.white,
        AkomButtonVariant.outlined => AkomColors.primary,
        AkomButtonVariant.ghost => AkomColors.primary,
        AkomButtonVariant.danger => Colors.white,
      };
}
