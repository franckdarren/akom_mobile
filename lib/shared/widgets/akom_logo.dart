import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wordmark Akôm — identique au composant `Logo` de akom_saas
/// (components/ui/logo.tsx) : "AK" + "Ô" en bleu de marque + "M".
class AkomLogo extends StatelessWidget {
  const AkomLogo({super.key, this.fontSize = 32, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AkomColors.onSurface;
    return Semantics(
      label: 'Akôm',
      child: ExcludeSemantics(
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: fontSize * 0.08,
              color: base,
              height: 1,
            ),
            children: [
              const TextSpan(text: 'AK'),
              const TextSpan(
                text: 'Ô',
                style: TextStyle(color: AkomColors.primary),
              ),
              const TextSpan(text: 'M'),
            ],
          ),
        ),
      ),
    );
  }
}
