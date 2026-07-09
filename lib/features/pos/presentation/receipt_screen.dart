import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/storage/local_storage.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/fcfa_formatter.dart';
import '../data/pos_providers.dart';
import '../data/thermal_printer_service.dart';
import '../domain/cart_item_model.dart';
import '../domain/order_result_model.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.extra});

  /// extra map keys: result, items, paymentMethod, received
  final Map<String, dynamic> extra;

  OrderResult get _result => extra['result'] as OrderResult;
  List<CartItem> get _items => (extra['items'] as List).cast<CartItem>();
  String get _paymentMethod => extra['paymentMethod'] as String;
  int? get _received => extra['received'] as int?;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantName =
        ref.read(localStorageProvider).restaurantName ?? 'Akôm Scanner';
    final total = _items.fold(0, (sum, i) => sum + i.subtotal);
    final change = (_received != null && _received! > total)
        ? _received! - total
        : 0;
    final printerState = ref.watch(printerConnectionProvider);
    final isPrinting = printerState.isPrinting;

    return Scaffold(
      appBar: AppBar(title: const Text('Reçu')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AkomSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge succès
                    Container(
                      padding: const EdgeInsets.all(AkomSpacing.md),
                      decoration: BoxDecoration(
                        color: AkomColors.successLight,
                        borderRadius: AkomRadius.borderMd,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AkomColors.success, size: 32),
                          const SizedBox(width: AkomSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vente enregistrée',
                                  style: AkomTextStyles.headlineSmall
                                      .copyWith(color: AkomColors.success)),
                              Text(
                                'Commande ${_result.orderNumber}',
                                style: AkomTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AkomSpacing.lg),

                    // Résumé articles
                    Text('Articles', style: AkomTextStyles.titleLarge),
                    const SizedBox(height: AkomSpacing.sm),
                    Card(
                      child: Column(
                        children: [
                          ..._items.map(
                            (item) => ListTile(
                              dense: true,
                              title: Text(item.name,
                                  style: AkomTextStyles.bodyMedium),
                              subtitle: Text(
                                '${item.quantity} × ${formatFCFA(item.price)}',
                                style: AkomTextStyles.bodySmall,
                              ),
                              trailing: Text(
                                formatFCFA(item.subtotal),
                                style: AkomTextStyles.titleMedium,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Total',
                                style: AkomTextStyles.headlineSmall),
                            trailing: Text(
                              formatFCFA(total),
                              style: AkomTextStyles.priceLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AkomSpacing.md),

                    // Paiement
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AkomSpacing.md),
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Mode de paiement',
                              value: _paymentLabel(_paymentMethod),
                            ),
                            if (_received != null) ...[
                              const SizedBox(height: AkomSpacing.sm),
                              _InfoRow(
                                label: 'Montant reçu',
                                value: formatFCFA(_received!),
                              ),
                              const SizedBox(height: AkomSpacing.sm),
                              _InfoRow(
                                label: 'Monnaie rendue',
                                value: formatFCFA(change),
                                valueColor: AkomColors.success,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: AkomColors.surface,
              padding: const EdgeInsets.all(AkomSpacing.md),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (printerState.isConnected)
                      ElevatedButton.icon(
                        icon: isPrinting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AkomColors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.print_outlined),
                        label: Text(
                          isPrinting ? 'Impression…' : 'Imprimer (thermique)',
                        ),
                        onPressed: isPrinting
                            ? null
                            : () => _printThermal(
                                  context,
                                  ref,
                                  restaurantName,
                                ),
                      ),
                    if (printerState.isConnected)
                      const SizedBox(height: AkomSpacing.sm),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Partager / Imprimer le reçu PDF'),
                      onPressed: () => _sharePdf(restaurantName, total, change),
                    ),
                    const SizedBox(height: AkomSpacing.sm),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const Text('Nouvelle vente'),
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                        context.pop(); // reçu -> panier
                        context.pop(); // panier -> caisse
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePdf(
    String restaurantName,
    int total,
    int change,
  ) async {
    final bytes = await _buildPdf(restaurantName, total, change);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'recu_${_result.orderNumber.replaceAll('#', '')}.pdf',
    );
  }

  Future<Uint8List> _buildPdf(
    String restaurantName,
    int total,
    int change,
  ) async {
    final doc = pw.Document();
    final now = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity,
            marginAll: 4 * PdfPageFormat.mm),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(restaurantName,
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 4),
            pw.Text(now,
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center),
            pw.Text('Commande ${_result.orderNumber}',
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center),
            pw.Divider(),
            ..._items.map(
              (item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${item.name} x${item.quantity}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    formatFCFA(item.subtotal),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(formatFCFA(total),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('Paiement : ${_paymentLabel(_paymentMethod)}',
                style: const pw.TextStyle(fontSize: 9)),
            if (_received != null) ...[
              pw.Text('Reçu : ${formatFCFA(_received!)}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Monnaie : ${formatFCFA(change)}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
            pw.SizedBox(height: 8),
            pw.Text('Merci !',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );

    return doc.save();
  }

  Future<void> _printThermal(
    BuildContext context,
    WidgetRef ref,
    String restaurantName,
  ) async {
    final notifier = ref.read(printerConnectionProvider.notifier);
    final printer = ref.read(printerConnectionProvider).connectedPrinter;
    if (printer == null) return;

    notifier.setPrinting(true);
    try {
      await ref.read(thermalPrinterServiceProvider).printReceipt(
            printer: printer,
            restaurantName: restaurantName,
            result: _result,
            items: _items,
            paymentMethod: _paymentMethod,
            received: _received,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impression envoyée'),
            backgroundColor: AkomColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AkomColors.error,
          ),
        );
      }
    } finally {
      notifier.setPrinting(false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: AkomTextStyles.bodyMedium
                  .copyWith(color: AkomColors.onSurfaceVariant)),
        ),
        const SizedBox(width: AkomSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: AkomTextStyles.titleMedium.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

String _paymentLabel(String method) => switch (method) {
      'airtel_money' => 'Airtel Money',
      'moov_money' => 'Moov Money',
      _ => 'Espèces (Cash)',
    };
