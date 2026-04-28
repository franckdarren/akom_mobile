import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/local_storage.dart';
import '../../../shared/utils/fcfa_formatter.dart';
import '../domain/cart_item_model.dart';
import '../domain/order_result_model.dart';

export 'package:flutter_thermal_printer/utils/printer.dart' show Printer, ConnectionType;
export 'package:flutter_thermal_printer/flutter_thermal_printer.dart' show FlutterThermalPrinter;

// ── Providers ─────────────────────────────────────────────────────────────────

final thermalPrinterServiceProvider = Provider<ThermalPrinterService>((ref) {
  return const ThermalPrinterService();
});

final printerConnectionProvider =
    StateNotifierProvider<PrinterConnectionNotifier, PrinterConnectionState>(
  (ref) => PrinterConnectionNotifier(ref.watch(localStorageProvider)),
);

// ── État de connexion ──────────────────────────────────────────────────────────

class PrinterConnectionState {
  const PrinterConnectionState({
    this.connectedPrinter,
    this.isConnecting = false,
    this.isPrinting = false,
    this.error,
  });

  final Printer? connectedPrinter;
  final bool isConnecting;
  final bool isPrinting;
  final String? error;

  bool get isConnected => connectedPrinter != null;

  PrinterConnectionState copyWith({
    Printer? connectedPrinter,
    bool? isConnecting,
    bool? isPrinting,
    String? error,
    bool clearPrinter = false,
    bool clearError = false,
  }) {
    return PrinterConnectionState(
      connectedPrinter: clearPrinter ? null : (connectedPrinter ?? this.connectedPrinter),
      isConnecting: isConnecting ?? this.isConnecting,
      isPrinting: isPrinting ?? this.isPrinting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PrinterConnectionNotifier extends StateNotifier<PrinterConnectionState> {
  PrinterConnectionNotifier(this._storage)
      : super(const PrinterConnectionState());

  final LocalStorage _storage;

  Future<void> connect(Printer printer) async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final success = await FlutterThermalPrinter.instance.connect(printer);
      if (success) {
        await _storage.savePrinter(
          address: printer.address ?? '',
          name: printer.name ?? 'Imprimante',
        );
        state = state.copyWith(connectedPrinter: printer, isConnecting: false);
      } else {
        state = state.copyWith(
          isConnecting: false,
          error: 'Connexion échouée',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: 'Erreur de connexion : $e',
      );
    }
  }

  Future<void> disconnect() async {
    final printer = state.connectedPrinter;
    if (printer != null) {
      try {
        await FlutterThermalPrinter.instance.disconnect(printer);
      } catch (_) {}
    }
    await _storage.clearPrinter();
    state = state.copyWith(clearPrinter: true, clearError: true);
  }

  void setError(String error) => state = state.copyWith(error: error);
  void setPrinting(bool value) => state = state.copyWith(isPrinting: value);
}

// ── Service ───────────────────────────────────────────────────────────────────

class ThermalPrinterService {
  const ThermalPrinterService();

  Stream<List<Printer>> get devicesStream =>
      FlutterThermalPrinter.instance.devicesStream;

  Future<void> startScan() async {
    await FlutterThermalPrinter.instance.getPrinters(
      connectionTypes: [ConnectionType.BLE],
    );
  }

  Future<void> stopScan() async {
    await FlutterThermalPrinter.instance.stopScan();
  }

  Future<void> printReceipt({
    required Printer printer,
    required String restaurantName,
    required OrderResult result,
    required List<CartItem> items,
    required String paymentMethod,
    int? received,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final bytes = await _buildEscPosBytes(
      restaurantName: restaurantName,
      result: result,
      items: items,
      paymentMethod: paymentMethod,
      received: received,
      paperSize: paperSize,
    );

    await FlutterThermalPrinter.instance.printData(
      printer,
      bytes,
      longData: true,
    );
  }

  Future<void> printTest(Printer printer) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(PaperSize.mm58, profile);
    final List<int> bytes = [];
    bytes.addAll(gen.reset());
    bytes.addAll(gen.text(
      'Test Akôm Scanner',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    ));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());

    await FlutterThermalPrinter.instance.printData(printer, bytes);
  }

  Future<List<int>> _buildEscPosBytes({
    required String restaurantName,
    required OrderResult result,
    required List<CartItem> items,
    required String paymentMethod,
    int? received,
    required PaperSize paperSize,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperSize, profile);
    final List<int> bytes = [];
    final total = items.fold(0, (sum, i) => sum + i.subtotal);
    final change = (received != null && received > total) ? received - total : 0;
    final now = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now());

    bytes.addAll(gen.reset());
    bytes.addAll(gen.text(
      restaurantName,
      styles: const PosStyles(bold: true, align: PosAlign.center),
    ));
    bytes.addAll(gen.text(now, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.text('Cmd ${result.orderNumber}', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.hr());

    for (final item in items) {
      bytes.addAll(gen.row([
        PosColumn(
          text: '${item.name} x${item.quantity}',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: formatFCFA(item.subtotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(gen.hr());
    bytes.addAll(gen.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(bold: true, align: PosAlign.left),
      ),
      PosColumn(
        text: formatFCFA(total),
        width: 6,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]));
    bytes.addAll(gen.text('Paiement : ${_paymentLabel(paymentMethod)}'));
    if (received != null) {
      bytes.addAll(gen.text('Reçu : ${formatFCFA(received)}'));
      bytes.addAll(gen.text('Monnaie : ${formatFCFA(change)}'));
    }
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.text('Merci !', styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(gen.feed(3));
    bytes.addAll(gen.cut());

    return bytes;
  }
}

String _paymentLabel(String method) => switch (method) {
      'airtel_money' => 'Airtel Money',
      'moov_money' => 'Moov Money',
      _ => 'Espèces (Cash)',
    };
