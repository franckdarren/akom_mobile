import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/stock_item_model.dart';
import 'inventory_repository.dart';

export 'inventory_repository.dart' show inventoryRepositoryProvider;

// ── Stock chargé depuis l'API ─────────────────────────────────────────────

final stockProvider =
    FutureProvider.autoDispose<List<StockItem>>((ref) async {
  return ref.read(inventoryRepositoryProvider).getStock();
});

// ── Session d'inventaire (scans en cours) ─────────────────────────────────

class InventorySessionNotifier extends Notifier<List<InventoryEntry>> {
  @override
  List<InventoryEntry> build() => [];

  void addOrUpdate(InventoryEntry entry) {
    final idx = state.indexWhere((e) => e.stock.productId == entry.stock.productId);
    if (idx == -1) {
      state = [...state, entry];
    } else {
      final updated = [...state];
      updated[idx] = entry;
      state = updated;
    }
  }

  void remove(String productId) {
    state = state.where((e) => e.stock.productId != productId).toList();
  }

  void clear() => state = [];

  bool hasProduct(String productId) =>
      state.any((e) => e.stock.productId == productId);

  InventoryEntry? getEntry(String productId) =>
      state.where((e) => e.stock.productId == productId).firstOrNull;
}

final inventorySessionProvider =
    NotifierProvider<InventorySessionNotifier, List<InventoryEntry>>(
  InventorySessionNotifier.new,
);
