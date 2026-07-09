import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/scan_feedback.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../data/catalog_providers.dart';
import '../domain/product_draft.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_controller.stop());
      case AppLifecycleState.resumed:
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    unawaited(ScanFeedback.beep());
    setState(() => _isProcessing = true);
    await _controller.stop();

    try {
      // Cherche d'abord dans Akôm
      final existing = await ref
          .read(productRepositoryProvider)
          .getProductByBarcode(barcode);

      if (!mounted) return;

      if (existing != null) {
        // Produit déjà dans Akôm → ouvrir l'édition
        context.pushReplacement(
          '/catalog/product/${existing.id}/edit',
          extra: existing,
        );
        return;
      }

      // Inconnu dans Akôm → essayer Open Food Facts
      final draft = await ref
          .read(openFoodFactsServiceProvider)
          .lookupBarcode(barcode);

      if (!mounted) return;

      final prefilled = (draft ?? const ProductDraft()).copyWith(barcode: barcode);
      context.pushReplacement('/catalog/new', extra: prefilled);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _manualEntry() {
    context.pushReplacement('/catalog/new');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner un produit'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Lampe torche',
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        message: 'Recherche du produit…',
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            // Viseur central
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
            // Bouton saisie manuelle
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black45,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AkomSpacing.lg,
                      vertical: AkomSpacing.sm,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AkomRadius.borderFull,
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Saisie manuelle'),
                  onPressed: _manualEntry,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Évite le warning "unawaited future" sans bloquer
void unawaited(Future<void> future) {}
