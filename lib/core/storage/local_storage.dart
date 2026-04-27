import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

final localStorageProvider = Provider<LocalStorage>(
  (ref) => LocalStorage(ref.watch(sharedPreferencesProvider)),
);

class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyRestaurantId = 'restaurant_id';
  static const _keyRestaurantName = 'restaurant_name';

  String? get accessToken => _prefs.getString(_keyAccessToken);
  String? get refreshToken => _prefs.getString(_keyRefreshToken);
  String? get restaurantId => _prefs.getString(_keyRestaurantId);
  String? get restaurantName => _prefs.getString(_keyRestaurantName);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _prefs.setString(_keyAccessToken, accessToken),
      _prefs.setString(_keyRefreshToken, refreshToken),
    ]);
  }

  Future<void> saveRestaurant({required String id, required String name}) async {
    await Future.wait([
      _prefs.setString(_keyRestaurantId, id),
      _prefs.setString(_keyRestaurantName, name),
    ]);
  }

  Future<void> clearAll() async {
    await Future.wait([
      _prefs.remove(_keyAccessToken),
      _prefs.remove(_keyRefreshToken),
      _prefs.remove(_keyRestaurantId),
      _prefs.remove(_keyRestaurantName),
    ]);
  }
}
