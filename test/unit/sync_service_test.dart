import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqlite3/open.dart';

import 'package:akom_scanner/core/database/app_database.dart';
import 'package:akom_scanner/core/sync/sync_service.dart';

class MockDio extends Mock implements Dio {}

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  setUpAll(() {
    // libsqlite3.so n'est pas présent sur Linux sans libsqlite3-dev ;
    // on charge directement la version versionnée.
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  late AppDatabase db;
  late MockDio mockDio;
  late SyncService service;

  setUp(() {
    db = _testDb();
    mockDio = MockDio();
    service = SyncService(db: db, dio: mockDio);
  });

  tearDown(() => db.close());

  group('SyncService — produits', () {
    test('syncs pending product successfully', () async {
      // Arrange: insert a pending product
      await db.pendingProductDao.insert(
        PendingProductsCompanion.insert(
          id: 'local-1',
          restaurantId: 'resto-1',
          name: 'Produit A',
          price: 5000,
          createdAt: DateTime.now(),
        ),
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'product': {
              'id': 'srv-1',
              'name': 'Produit A',
              'price': 5000,
            }
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/products'),
        ),
      );

      // Act
      await service.sync();

      // Assert: pending cleared, product cached, log written
      final pending = await db.pendingProductDao.getPending();
      expect(pending, isEmpty);

      final cached = await db.productDao.getById('srv-1');
      expect(cached, isNotNull);
      expect(cached!.name, 'Produit A');

      final logs = await db.syncLogDao.getRecent();
      expect(logs.length, 1);
      expect(logs.first.success, isTrue);
      expect(logs.first.type, 'product');
    });

    test('marks pending product as error on Dio failure', () async {
      await db.pendingProductDao.insert(
        PendingProductsCompanion.insert(
          id: 'local-2',
          restaurantId: 'resto-1',
          name: 'Produit B',
          price: 1000,
          createdAt: DateTime.now(),
        ),
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/products'),
          message: 'connection refused',
        ),
      );

      await service.sync();

      // Pending stays (with error status)
      final rows = await (db.select(db.pendingProducts)
            ..where((t) => t.id.equals('local-2')))
          .get();
      expect(rows.first.status, 'error');

      // Log records the failure
      final logs = await db.syncLogDao.getRecent();
      expect(logs.first.success, isFalse);
    });
  });

  group('SyncService — stock', () {
    test('syncs pending stock entry successfully', () async {
      await db.stockDao.insert(
        PendingStockEntriesCompanion.insert(
          productId: 'prod-1',
          restaurantId: 'resto-1',
          quantity: 42,
          createdAt: DateTime.now(),
        ),
      );

      when(
        () => mockDio.patch<void>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/stock/prod-1'),
        ),
      );

      await service.sync();

      final pending = await db.stockDao.getPending();
      expect(pending, isEmpty);

      final logs = await db.syncLogDao.getRecent();
      expect(logs.first.success, isTrue);
      expect(logs.first.type, 'stock');
    });

    test('marks pending stock as error on Dio failure', () async {
      await db.stockDao.insert(
        PendingStockEntriesCompanion.insert(
          productId: 'prod-2',
          restaurantId: 'resto-1',
          quantity: 10,
          createdAt: DateTime.now(),
        ),
      );

      when(
        () => mockDio.patch<void>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/stock/prod-2'),
        ),
      );

      await service.sync();

      final rows = await db.stockDao.getPending();
      // Row still exists but as 'error' (getPending() filters 'pending' only)
      expect(rows, isEmpty);
      final logs = await db.syncLogDao.getRecent();
      expect(logs.first.success, isFalse);
    });

    test('sync is no-op when nothing is pending', () async {
      await service.sync();
      final logs = await db.syncLogDao.getRecent();
      expect(logs, isEmpty);
      verifyNever(() => mockDio.post<dynamic>(any()));
      verifyNever(() => mockDio.patch<dynamic>(any()));
    });
  });
}
