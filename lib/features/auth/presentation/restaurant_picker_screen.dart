import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/local_storage.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/akom_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../data/auth_provider.dart';
import '../domain/restaurant_model.dart';

class RestaurantPickerScreen extends ConsumerStatefulWidget {
  const RestaurantPickerScreen({super.key});

  @override
  ConsumerState<RestaurantPickerScreen> createState() =>
      _RestaurantPickerScreenState();
}

class _RestaurantPickerScreenState
    extends ConsumerState<RestaurantPickerScreen> {
  bool _isSelecting = false;

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    // Auto-sélection si un seul restaurant
    ref.listen(restaurantsProvider, (_, next) {
      next.whenData((restaurants) {
        if (restaurants.length == 1) {
          _selectRestaurant(restaurants.first);
        }
      });
    });

    return Scaffold(
      backgroundColor: AkomColors.background,
      appBar: AppBar(
        title: const Text('Choisir un restaurant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _isSelecting ? null : _signOut,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isSelecting,
        message: 'Sélection du restaurant…',
        child: restaurantsAsync.when(
          loading: () => const Center(child: InlineLoader()),
          error: (error, _) => _ErrorBody(
            message: error.toString(),
            onRetry: () => ref.invalidate(restaurantsProvider),
          ),
          data: (restaurants) {
            if (restaurants.isEmpty) {
              return EmptyState(
                icon: Icons.store_outlined,
                title: 'Aucun restaurant',
                subtitle:
                    'Votre compte n\'est associé à aucun restaurant.\nContactez votre administrateur sur akom.app.',
                action: _signOut,
                actionLabel: 'Se déconnecter',
              );
            }

            // Si un seul restaurant, affiche un loader pendant l'auto-sélection
            if (restaurants.length == 1) {
              return const Center(child: InlineLoader());
            }

            return _RestaurantList(
              restaurants: restaurants,
              onSelect: _selectRestaurant,
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectRestaurant(RestaurantModel restaurant) async {
    if (_isSelecting) return;
    setState(() => _isSelecting = true);
    try {
      await ref
          .read(localStorageProvider)
          .saveRestaurant(id: restaurant.id, name: restaurant.name);

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _isSelecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de sélectionner ce restaurant : $e'),
            backgroundColor: AkomColors.error,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    // RouterAuthNotifier détecte le logout et GoRouter redirige vers /login
  }
}

class _RestaurantList extends StatelessWidget {
  const _RestaurantList({
    required this.restaurants,
    required this.onSelect,
  });

  final List<RestaurantModel> restaurants;
  final ValueChanged<RestaurantModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AkomSpacing.md),
      itemCount: restaurants.length,
      separatorBuilder: (_, _) => const SizedBox(height: AkomSpacing.sm),
      itemBuilder: (_, index) => _RestaurantCard(
        restaurant: restaurants[index],
        onTap: () => onSelect(restaurants[index]),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant, required this.onTap});

  final RestaurantModel restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AkomRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.all(AkomSpacing.md),
          child: Row(
            children: [
              _RestaurantAvatar(
                name: restaurant.name,
                logoUrl: restaurant.logoUrl,
              ),
              const SizedBox(width: AkomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name, style: AkomTextStyles.titleLarge),
                    if (restaurant.slug != null)
                      Text(
                        restaurant.slug!,
                        style: AkomTextStyles.bodySmall,
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AkomColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantAvatar extends StatelessWidget {
  const _RestaurantAvatar({required this.name, this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: AkomRadius.borderSm,
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _Fallback(name: name, size: size),
        ),
      );
    }
    return _Fallback(name: name, size: size);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AkomColors.primary.withAlpha(26),
        borderRadius: AkomRadius.borderSm,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AkomTextStyles.headlineSmall
            .copyWith(color: AkomColors.primary),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AkomSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AkomColors.error),
          const SizedBox(height: AkomSpacing.md),
          Text(
            message,
            style:
                AkomTextStyles.bodyMedium.copyWith(color: AkomColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkomSpacing.xl),
          AkomButton(
            label: 'Réessayer',
            onPressed: onRetry,
            isFullWidth: false,
            size: AkomButtonSize.medium,
          ),
        ],
      ),
    );
  }
}
