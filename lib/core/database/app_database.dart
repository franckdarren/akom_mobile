import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get restaurantId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get price => integer()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingProducts extends Table {
  TextColumn get id => text()();
  TextColumn get restaurantId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get price => integer()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  // 'pending' | 'syncing' | 'error'
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Nommée PendingStockEntries pour que le type de ligne généré soit PendingStockEntry
class PendingStockEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productId => text()();
  TextColumn get restaurantId => text()();
  IntColumn get quantity => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
}

class SyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 'product' | 'stock'
  TextColumn get type => text()();
  TextColumn get entityId => text()();
  BoolColumn get success => boolean()();
  TextColumn get message => text().nullable()();
  DateTimeColumn get syncedAt => dateTime()();
}

// ---------------------------------------------------------------------------
// DAOs
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [LocalProducts])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<List<LocalProduct>> getAllForRestaurant(String restaurantId) =>
      (select(localProducts)
            ..where((t) => t.restaurantId.equals(restaurantId)))
          .get();

  Future<LocalProduct?> getById(String id) =>
      (select(localProducts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<LocalProduct?> getByBarcode(String barcode) =>
      (select(localProducts)..where((t) => t.barcode.equals(barcode)))
          .getSingleOrNull();

  Future<void> upsertProduct(LocalProductsCompanion product) =>
      into(localProducts).insertOnConflictUpdate(product);

  Future<void> upsertProducts(List<LocalProductsCompanion> products) =>
      batch((b) => b.insertAllOnConflictUpdate(localProducts, products));

  Future<void> deleteProduct(String id) =>
      (delete(localProducts)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [PendingProducts])
class PendingProductDao extends DatabaseAccessor<AppDatabase>
    with _$PendingProductDaoMixin {
  PendingProductDao(super.db);

  Future<List<PendingProduct>> getPending() =>
      (select(pendingProducts)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  Future<void> insert(PendingProductsCompanion product) =>
      into(pendingProducts).insert(product);

  Future<void> updateStatus(
    String id,
    String status, {
    String? errorMessage,
  }) =>
      (update(pendingProducts)..where((t) => t.id.equals(id))).write(
        PendingProductsCompanion(
          status: Value(status),
          errorMessage: Value(errorMessage),
        ),
      );

  Future<void> deleteById(String id) =>
      (delete(pendingProducts)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [PendingStockEntries])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(super.db);

  Future<List<PendingStockEntry>> getPending() =>
      (select(pendingStockEntries)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  Future<void> insert(PendingStockEntriesCompanion entry) =>
      into(pendingStockEntries).insert(entry);

  Future<void> updateStatus(
    int id,
    String status, {
    String? errorMessage,
  }) =>
      (update(pendingStockEntries)..where((t) => t.id.equals(id))).write(
        PendingStockEntriesCompanion(
          status: Value(status),
          errorMessage: Value(errorMessage),
        ),
      );

  Future<void> deleteById(int id) =>
      (delete(pendingStockEntries)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [SyncLogs])
class SyncLogDao extends DatabaseAccessor<AppDatabase> with _$SyncLogDaoMixin {
  SyncLogDao(super.db);

  Future<void> log({
    required String type,
    required String entityId,
    required bool success,
    String? message,
  }) =>
      into(syncLogs).insert(
        SyncLogsCompanion.insert(
          type: type,
          entityId: entityId,
          success: success,
          syncedAt: DateTime.now(),
          message: Value(message),
        ),
      );

  Future<List<SyncLog>> getRecent({int limit = 50}) =>
      (select(syncLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.syncedAt)])
            ..limit(limit))
          .get();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [LocalProducts, PendingProducts, PendingStockEntries, SyncLogs],
  daos: [ProductDao, PendingProductDao, StockDao, SyncLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'akom_scanner');
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
