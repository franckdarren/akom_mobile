import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'core/network/connectivity.dart';
import 'core/storage/local_storage.dart';
import 'core/sync/sync_service.dart';
import 'features/auth/data/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/restaurant_picker_screen.dart';
import 'features/catalog/domain/product_draft.dart';
import 'features/catalog/domain/product_model.dart';
import 'features/catalog/presentation/catalog_screen.dart';
import 'features/catalog/presentation/product_form_screen.dart';
import 'features/catalog/presentation/qr_label_screen.dart';
import 'features/catalog/presentation/scanner_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'shared/theme/app_theme.dart';

// Placeholders — remplacés en Phases 6, 7
class _InventoryPlaceholder extends StatelessWidget {
  const _InventoryPlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Inventaire')),
        body: const Center(child: Text('Inventaire — Phase 6')),
      );
}

class _PosPlaceholder extends StatelessWidget {
  const _PosPlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Caisse')),
        body: const Center(child: Text('Caisse — Phase 7')),
      );
}

final _routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(routerAuthNotifierProvider);
  final storage = ref.watch(localStorageProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final session = sb.Supabase.instance.client.auth.currentSession;
      final loc = state.matchedLocation;

      // Pas de session → toujours vers /login
      if (session == null) {
        return loc == '/login' ? null : '/login';
      }

      // Session valide mais pas de restaurant sélectionné → /restaurants
      final rid = storage.restaurantId;
      if (rid == null || rid.isEmpty) {
        return loc == '/restaurants' ? null : '/restaurants';
      }

      // Session valide + restaurant → sortir des écrans d'auth
      if (loc == '/login' || loc == '/restaurants') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/restaurants',
        builder: (context, state) => const RestaurantPickerScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/catalog',
        builder: (_, _) => const CatalogScreen(),
        routes: [
          GoRoute(
            path: 'scanner',
            builder: (_, _) => const ScannerScreen(),
          ),
          GoRoute(
            path: 'new',
            builder: (_, state) => ProductFormScreen(
              initialDraft: state.extra as ProductDraft?,
            ),
          ),
          GoRoute(
            path: 'product/:id/edit',
            builder: (_, state) => ProductFormScreen(
              product: state.extra as ProductModel?,
            ),
          ),
          GoRoute(
            path: 'product/:id/qr',
            builder: (_, state) => QrLabelScreen(
              product: state.extra! as ProductModel,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const _InventoryPlaceholder(),
      ),
      GoRoute(
        path: '/pos',
        builder: (context, state) => const _PosPlaceholder(),
      ),
    ],
  );
});

class AkomApp extends ConsumerWidget {
  const AkomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, current) {
      final wasOffline = previous?.valueOrNull == false;
      final isNowOnline = current.valueOrNull == true;
      if (wasOffline && isNowOnline) {
        ref.read(syncServiceProvider).sync();
      }
    });

    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'Akôm Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
