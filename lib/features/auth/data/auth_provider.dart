import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/restaurant_model.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioClientProvider),
    storage: ref.watch(localStorageProvider),
  );
});

// Émet chaque changement d'état d'authentification Supabase (login, logout, refresh)
final authStateProvider = StreamProvider<sb.AuthState>((ref) {
  return sb.Supabase.instance.client.auth.onAuthStateChange;
});

// ID du restaurant actuellement sélectionné, lu depuis SharedPreferences
final currentRestaurantIdProvider = Provider<String?>((ref) {
  return ref.watch(localStorageProvider).restaurantId;
});

// Liste des restaurants accessibles à l'utilisateur connecté
final restaurantsProvider =
    FutureProvider.autoDispose<List<RestaurantModel>>((ref) {
  return ref.read(authRepositoryProvider).getRestaurantsForUser();
});

// ChangeNotifier utilisé par GoRouter pour déclencher le re-calcul des redirects
// lorsque la session Supabase change (login / logout / token refresh).
class RouterAuthNotifier extends ChangeNotifier {
  RouterAuthNotifier() {
    _sub = sb.Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }

  late final StreamSubscription<sb.AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerAuthNotifierProvider = Provider<RouterAuthNotifier>((ref) {
  final notifier = RouterAuthNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});
