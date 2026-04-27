import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/storage/local_storage.dart';
import '../../../features/auth/data/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/error_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantName = ref.watch(localStorageProvider).restaurantName ?? '';
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.store_outlined),
            tooltip: 'Changer de restaurant',
            onPressed: () async {
              await ref.read(localStorageProvider).saveRestaurant(
                    id: '',
                    name: '',
                  );
              if (context.mounted) context.go('/restaurants');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isOnline)
              const ErrorBanner(
                message: 'Mode hors ligne — synchronisation en attente',
                type: ErrorBannerType.offline,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AkomSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AkomSpacing.md),
                    Text(
                      'Que souhaitez-vous faire ?',
                      style: AkomTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AkomSpacing.lg),
                    Expanded(
                      child: Column(
                        children: [
                          _ModuleTile(
                            icon: Icons.inventory_2_outlined,
                            title: 'Catalogue',
                            subtitle: 'Gérer vos produits et codes-barres',
                            color: AkomColors.primary,
                            onTap: () => context.go('/catalog'),
                          ),
                          const SizedBox(height: AkomSpacing.md),
                          _ModuleTile(
                            icon: Icons.bar_chart_outlined,
                            title: 'Inventaire',
                            subtitle: 'Compter et ajuster votre stock',
                            color: AkomColors.secondary,
                            onTap: () => context.go('/inventory'),
                          ),
                          const SizedBox(height: AkomSpacing.md),
                          _ModuleTile(
                            icon: Icons.point_of_sale_outlined,
                            title: 'Caisse',
                            subtitle: 'Enregistrer des ventes',
                            color: const Color(0xFF1565C0),
                            onTap: () => context.go('/pos'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AkomSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: AkomRadius.borderMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AkomSpacing.lg,
              vertical: AkomSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: AkomRadius.borderMd,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: AkomSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: AkomTextStyles.headlineSmall),
                      const SizedBox(height: AkomSpacing.xs),
                      Text(
                        subtitle,
                        style: AkomTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AkomSpacing.sm),
                Icon(
                  Icons.chevron_right,
                  color: AkomColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
