import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withAlpha(102),
              child: Center(
                child: _LoadingCard(message: message),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AkomSpacing.xl,
        vertical: AkomSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AkomColors.surface,
        borderRadius: AkomRadius.borderLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AkomColors.primary),
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: AkomSpacing.md),
            Text(
              message!,
              style: AkomTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// Version légère pour les listes / sections partielles
class InlineLoader extends StatelessWidget {
  const InlineLoader({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AkomSpacing.lg),
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AkomColors.primary),
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}
