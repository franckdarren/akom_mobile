import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/fcfa_formatter.dart';
import '../data/pos_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    if (cart.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        actions: [
          TextButton(
            onPressed: () => _confirmClear(context, ref),
            child: Text(
              'Vider',
              style: TextStyle(color: AkomColors.onPrimary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AkomSpacing.sm),
              itemCount: cart.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cart[index];
                return ListTile(
                  title: Text(item.name, style: AkomTextStyles.titleMedium),
                  subtitle: Text(
                    formatFCFA(item.price),
                    style: AkomTextStyles.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () =>
                            ref.read(cartProvider.notifier).decrement(item.productId),
                        color: AkomColors.onSurfaceVariant,
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: AkomTextStyles.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () =>
                            ref.read(cartProvider.notifier).increment(item.productId),
                        color: AkomColors.primary,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            color: AkomColors.surface,
            padding: const EdgeInsets.all(AkomSpacing.md),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: AkomTextStyles.headlineSmall),
                      Text(formatFCFA(total), style: AkomTextStyles.priceLarge),
                    ],
                  ),
                  const SizedBox(height: AkomSpacing.md),
                  ElevatedButton(
                    onPressed: () => context.push('/pos/payment'),
                    child: const Text('Valider la vente'),
                  ),
                  const SizedBox(height: AkomSpacing.sm),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Continuer les achats'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content: const Text('Tous les articles seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Vider', style: TextStyle(color: AkomColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(cartProvider.notifier).clearCart();
      if (context.mounted) context.pop();
    }
  }
}
