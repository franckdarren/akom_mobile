import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum ErrorBannerType { error, offline, warning, info }

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.type = ErrorBannerType.error,
    this.onRetry,
    this.onDismiss,
  });

  final String message;
  final ErrorBannerType type;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  factory ErrorBanner.offline({VoidCallback? onRetry}) {
    return ErrorBanner(
      message: 'Hors ligne — les modifications seront synchronisées au retour',
      type: ErrorBannerType.offline,
      onRetry: onRetry,
    );
  }

  factory ErrorBanner.error({
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return ErrorBanner(
      message: message,
      type: ErrorBannerType.error,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, icon) = _style;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AkomSpacing.md,
        vertical: AkomSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AkomRadius.borderSm,
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: AkomSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AkomTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AkomSpacing.sm),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Réessayer',
                style: AkomTextStyles.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: AkomSpacing.sm),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: textColor, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color, IconData) get _style => switch (type) {
        ErrorBannerType.error => (
            AkomColors.errorLight,
            AkomColors.error,
            Icons.error_outline,
          ),
        ErrorBannerType.offline => (
            const Color(0xFFEEEEEE),
            AkomColors.offline,
            Icons.wifi_off,
          ),
        ErrorBannerType.warning => (
            AkomColors.warningLight,
            AkomColors.warning,
            Icons.warning_amber_outlined,
          ),
        ErrorBannerType.info => (
            const Color(0xFFE3F2FD),
            const Color(0xFF1565C0),
            Icons.info_outline,
          ),
      };
}
