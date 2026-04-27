import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/error_banner.dart';
import '../data/inventory_providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final session = ref.watch(inventorySessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventaire')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isOnline)
              const ErrorBanner(
                message: 'Mode hors ligne — les ajustements seront synchronisés au retour de la connexion',
                type: ErrorBannerType.offline,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AkomSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AkomSpacing.md),
                    Text('Inventaire de stock', style: AkomTextStyles.headlineMedium),
                    const SizedBox(height: AkomSpacing.sm),
                    Text(
                      'Scannez chaque produit et saisissez la quantité physique comptée.',
                      style: AkomTextStyles.bodyMedium
                          .copyWith(color: AkomColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AkomSpacing.xl),
                    if (session.isNotEmpty) ...[
                      _SessionSummaryCard(session: session),
                      const SizedBox(height: AkomSpacing.md),
                    ],
                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(
                        session.isEmpty
                            ? 'Démarrer l\'inventaire'
                            : 'Continuer l\'inventaire',
                      ),
                      onPressed: () => context.push('/inventory/scan'),
                    ),
                    if (session.isNotEmpty) ...[
                      const SizedBox(height: AkomSpacing.sm),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.summarize_outlined),
                        label: const Text('Voir le récapitulatif'),
                        onPressed: () => context.push('/inventory/summary'),
                      ),
                      const SizedBox(height: AkomSpacing.sm),
                      TextButton(
                        onPressed: () => _confirmReset(context, ref),
                        child: Text(
                          'Réinitialiser la session',
                          style: TextStyle(color: AkomColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser ?'),
        content: const Text('Tous les scans de cette session seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Réinitialiser', style: TextStyle(color: AkomColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(inventorySessionProvider.notifier).clear();
    }
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({required this.session});

  final List<dynamic> session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AkomSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AkomColors.secondary.withAlpha(26),
                borderRadius: AkomRadius.borderMd,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.inventory_2_outlined,
                  color: AkomColors.secondary),
            ),
            const SizedBox(width: AkomSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session en cours',
                    style: AkomTextStyles.titleMedium,
                  ),
                  Text(
                    '${session.length} produit${session.length > 1 ? 's' : ''} scanné${session.length > 1 ? 's' : ''}',
                    style: AkomTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
