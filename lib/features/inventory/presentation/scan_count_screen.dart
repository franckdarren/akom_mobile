import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/scan_feedback.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../data/inventory_providers.dart';
import '../domain/stock_item_model.dart';

// Évite le warning "unawaited future"
void _unawaited(Future<void> f) {}

class ScanCountScreen extends ConsumerStatefulWidget {
  const ScanCountScreen({super.key});

  @override
  ConsumerState<ScanCountScreen> createState() => _ScanCountScreenState();
}

class _ScanCountScreenState extends ConsumerState<ScanCountScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _scanner;
  bool _isProcessing = false;
  bool _torchOn = false;

  // Produit actuellement affiché pour comptage
  StockItem? _currentItem;
  final _qtyController = TextEditingController();
  final _qtyFocus = FocusNode();
  String? _qtyError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanner.dispose();
    _qtyController.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _unawaited(_scanner.stop());
      case AppLifecycleState.resumed:
        if (_currentItem == null) _unawaited(_scanner.start());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _currentItem != null) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    _unawaited(ScanFeedback.beep());
    setState(() => _isProcessing = true);
    _unawaited(_scanner.stop());

    final stockAsync = ref.read(stockProvider);
    final items = stockAsync.valueOrNull ?? [];

    StockItem? found;
    for (final item in items) {
      if (item.barcode == code || item.productId == code) {
        found = item;
        break;
      }
    }

    if (!mounted) return;

    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Produit introuvable dans le stock de ce restaurant.'),
          backgroundColor: AkomColors.error,
        ),
      );
      setState(() => _isProcessing = false);
      _unawaited(_scanner.start());
      return;
    }

    // Pré-remplir la quantité si déjà scannée dans cette session
    final existing = ref
        .read(inventorySessionProvider.notifier)
        .getEntry(found.productId);

    setState(() {
      _isProcessing = false;
      _currentItem = found;
      _qtyController.text =
          existing != null ? '${existing.countedQuantity}' : '';
      _qtyError = null;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _qtyFocus.requestFocus();
  }

  void _validate() {
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 0) {
      setState(() => _qtyError = 'Entrez une quantité valide (≥ 0)');
      return;
    }
    final item = _currentItem!;
    ref.read(inventorySessionProvider.notifier).addOrUpdate(
          InventoryEntry(
            stock: item,
            countedQuantity: qty,
            countedAt: DateTime.now(),
          ),
        );

    // Feedback visuel rapide puis retour au scan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.productName} — $qty unité${qty > 1 ? 's' : ''} enregistrée${qty > 1 ? 's' : ''}'),
        backgroundColor: AkomColors.success,
        duration: const Duration(seconds: 1),
      ),
    );

    setState(() {
      _currentItem = null;
      _qtyController.clear();
      _qtyError = null;
    });
    _unawaited(_scanner.start());
  }

  void _cancelCurrent() {
    setState(() {
      _currentItem = null;
      _qtyController.clear();
      _qtyError = null;
    });
    _unawaited(_scanner.start());
  }

  @override
  Widget build(BuildContext context) {
    // Précharge le stock dès l'ouverture de l'écran
    ref.watch(stockProvider);
    final session = ref.watch(inventorySessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Inventaire — ${session.length} produit${session.length > 1 ? 's' : ''}',
        ),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _scanner.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          TextButton(
            onPressed: session.isNotEmpty
                ? () => context.pushReplacement('/inventory/summary')
                : null,
            child: Text(
              'Terminer',
              style: TextStyle(
                color: session.isNotEmpty ? AkomColors.secondary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        message: 'Recherche du produit…',
        child: _currentItem != null
            ? _CountEntryPanel(
                item: _currentItem!,
                controller: _qtyController,
                focusNode: _qtyFocus,
                error: _qtyError,
                onValidate: _validate,
                onCancel: _cancelCurrent,
                onChanged: () => setState(() {}),
              )
            : Stack(
                children: [
                  MobileScanner(
                    controller: _scanner,
                    onDetect: _onDetect,
                  ),
                  // Viseur
                  Center(
                    child: Container(
                      width: 240,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: AkomColors.secondary, width: 2),
                        borderRadius: AkomRadius.borderMd,
                      ),
                    ),
                  ),
                  // Indication
                  Positioned(
                    bottom: 48,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AkomSpacing.lg,
                          vertical: AkomSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: AkomRadius.borderFull,
                        ),
                        child: const Text(
                          'Scannez un produit (code-barres ou QR Akôm)',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CountEntryPanel extends StatelessWidget {
  const _CountEntryPanel({
    required this.item,
    required this.controller,
    required this.focusNode,
    required this.onValidate,
    required this.onCancel,
    required this.onChanged,
    this.error,
  });

  final StockItem item;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final VoidCallback onValidate;
  final VoidCallback onCancel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final gap = int.tryParse(controller.text) != null
        ? int.parse(controller.text) - item.quantity
        : null;

    return Container(
      color: AkomColors.background,
      padding: const EdgeInsets.all(AkomSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AkomSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AkomSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: AkomTextStyles.headlineSmall),
                  if (item.barcode != null)
                    Text(
                      item.barcode!,
                      style: AkomTextStyles.bodySmall,
                    ),
                  const SizedBox(height: AkomSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 16, color: AkomColors.onSurfaceVariant),
                      const SizedBox(width: AkomSpacing.xs),
                      Flexible(
                        child: Text(
                          'Stock théorique : ${item.quantity}',
                          style: AkomTextStyles.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AkomSpacing.lg),
          Text('Quantité comptée', style: AkomTextStyles.titleLarge),
          const SizedBox(height: AkomSpacing.sm),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AkomTextStyles.headlineLarge,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              errorText: error,
              suffixText: 'unités',
            ),
            onSubmitted: (_) => onValidate(),
            onChanged: (_) => onChanged(),
          ),
          if (gap != null) ...[
            const SizedBox(height: AkomSpacing.sm),
            _GapIndicator(gap: gap),
          ],
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Valider et scanner suivant'),
            onPressed: onValidate,
          ),
          const SizedBox(height: AkomSpacing.sm),
          OutlinedButton(
            onPressed: onCancel,
            child: const Text('Annuler'),
          ),
          const SizedBox(height: AkomSpacing.md),
        ],
      ),
    );
  }
}

class _GapIndicator extends StatelessWidget {
  const _GapIndicator({required this.gap});
  final int gap;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (gap == 0) {
      color = AkomColors.success;
      label = 'Conforme au stock théorique';
    } else if (gap > 0) {
      color = AkomColors.warning;
      label = 'Excédent : +$gap unité${gap > 1 ? 's' : ''}';
    } else {
      color = AkomColors.error;
      label = 'Manque : $gap unité${gap.abs() > 1 ? 's' : ''}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AkomSpacing.md,
        vertical: AkomSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: AkomRadius.borderMd,
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            gap == 0 ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
            size: 16,
          ),
          const SizedBox(width: AkomSpacing.xs),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}
