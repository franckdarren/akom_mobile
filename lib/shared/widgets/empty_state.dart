import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  factory EmptyState.products({VoidCallback? onAdd}) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Aucun produit',
      subtitle: 'Ajoutez votre premier produit en scannant son code-barres\n'
          'ou en utilisant la saisie manuelle.',
      action: onAdd,
      actionLabel: 'Ajouter un produit',
    );
  }

  factory EmptyState.search({required String query}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Aucun résultat',
      subtitle: 'Aucun produit ne correspond à "$query".',
    );
  }

  factory EmptyState.offline() {
    return const EmptyState(
      icon: Icons.wifi_off,
      title: 'Hors ligne',
      subtitle:
          'Impossible de charger les données.\nVérifiez votre connexion internet.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AkomSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 64,
                color: AkomColors.onSurfaceVariant.withAlpha(102),
              ),
            const SizedBox(height: AkomSpacing.lg),
            Text(
              title,
              style: AkomTextStyles.headlineSmall
                  .copyWith(color: AkomColors.onSurface),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AkomSpacing.sm),
              Text(
                subtitle!,
                style: AkomTextStyles.bodyMedium
                    .copyWith(color: AkomColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: AkomSpacing.xl),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: action,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AkomColors.primary,
                    foregroundColor: AkomColors.onPrimary,
                    minimumSize: const Size(0, 48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AkomRadius.borderMd,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AkomTextStyles.labelLarge,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
