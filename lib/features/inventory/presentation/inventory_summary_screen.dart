import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/inventory_providers.dart';
import '../domain/stock_item_model.dart';

class InventorySummaryScreen extends ConsumerStatefulWidget {
  const InventorySummaryScreen({super.key});

  @override
  ConsumerState<InventorySummaryScreen> createState() =>
      _InventorySummaryScreenState();
}

class _InventorySummaryScreenState
    extends ConsumerState<InventorySummaryScreen> {
  bool _isSyncing = false;
  String? _syncError;
  int _synced = 0;
  int _total = 0;
  bool _done = false;

  Future<void> _syncAll() async {
    final entries = ref.read(inventorySessionProvider);
    if (entries.isEmpty) return;

    setState(() {
      _isSyncing = true;
      _syncError = null;
      _synced = 0;
      _total = entries.length;
      _done = false;
    });

    final repo = ref.read(inventoryRepositoryProvider);
    final errors = <String>[];

    for (final entry in entries) {
      try {
        await repo.updateStock(
          entry.stock.productId,
          entry.countedQuantity,
          note: 'Inventaire mobile',
        );
        setState(() => _synced++);
      } on AppException catch (e) {
        errors.add('${entry.stock.productName} : ${e.message}');
      }
    }

    if (errors.isEmpty) {
      ref.read(inventorySessionProvider.notifier).clear();
      setState(() {
        _isSyncing = false;
        _done = true;
      });
    } else {
      setState(() {
        _isSyncing = false;
        _syncError = errors.join('\n');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(inventorySessionProvider);
    final totalGap = entries.fold(0, (sum, e) => sum + e.gap.abs());

    return Scaffold(
      appBar: AppBar(title: const Text('Récapitulatif inventaire')),
      body: Column(
        children: [
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Aucun produit scanné.'))
                : ListView(
                    children: [
                      // En-tête tableau
                      Container(
                        color: AkomColors.background,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AkomSpacing.md,
                          vertical: AkomSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text('Produit',
                                  style: AkomTextStyles.labelLarge),
                            ),
                            const SizedBox(
                              width: 48,
                              child: Text('Théo.',
                                  textAlign: TextAlign.center,
                                  style: AkomTextStyles.labelLarge),
                            ),
                            const SizedBox(
                              width: 48,
                              child: Text('Compté',
                                  textAlign: TextAlign.center,
                                  style: AkomTextStyles.labelLarge),
                            ),
                            const SizedBox(
                              width: 48,
                              child: Text('Écart',
                                  textAlign: TextAlign.center,
                                  style: AkomTextStyles.labelLarge),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ...entries.map((e) => _EntryRow(entry: e)),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(AkomSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total des écarts : $totalGap unité${totalGap > 1 ? 's' : ''}',
                                style: AkomTextStyles.titleMedium,
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Container(
            color: AkomColors.surface,
            padding: const EdgeInsets.all(AkomSpacing.md),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_syncError != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AkomSpacing.sm),
                      child: Text(
                        _syncError!,
                        style: TextStyle(color: AkomColors.error, fontSize: 13),
                      ),
                    ),
                  if (_done)
                    _DoneBanner(onReturn: () => context.go('/inventory'))
                  else ...[
                    if (_isSyncing)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _total > 0 ? _synced / _total : null,
                            color: AkomColors.primary,
                          ),
                          const SizedBox(height: AkomSpacing.sm),
                          Text(
                            'Synchronisation $_synced / $_total…',
                            textAlign: TextAlign.center,
                            style: AkomTextStyles.bodySmall,
                          ),
                          const SizedBox(height: AkomSpacing.sm),
                        ],
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(_syncError != null
                          ? 'Réessayer'
                          : 'Envoyer les ajustements'),
                      onPressed:
                          (_isSyncing || entries.isEmpty) ? null : _syncAll,
                    ),
                    const SizedBox(height: AkomSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Continuer l\'inventaire'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});
  final InventoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final gap = entry.gap;
    final gapColor = gap == 0
        ? AkomColors.success
        : gap > 0
            ? AkomColors.warning
            : AkomColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AkomSpacing.md,
        vertical: AkomSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AkomColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              entry.stock.productName,
              style: AkomTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${entry.stock.quantity}',
              textAlign: TextAlign.center,
              style: AkomTextStyles.bodyMedium,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${entry.countedQuantity}',
              textAlign: TextAlign.center,
              style: AkomTextStyles.bodyMedium,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              gap >= 0 ? '+$gap' : '$gap',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: gapColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneBanner extends StatelessWidget {
  const _DoneBanner({required this.onReturn});
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AkomSpacing.md),
          decoration: BoxDecoration(
            color: AkomColors.successLight,
            borderRadius: AkomRadius.borderMd,
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AkomColors.success),
              const SizedBox(width: AkomSpacing.sm),
              const Expanded(
                child: Text(
                  'Inventaire synchronisé avec succès !',
                  style: TextStyle(color: AkomColors.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AkomSpacing.md),
        ElevatedButton(
          onPressed: onReturn,
          child: const Text('Retour à l\'inventaire'),
        ),
      ],
    );
  }
}
