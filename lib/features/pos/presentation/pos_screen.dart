import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/connectivity.dart';
import '../../../features/catalog/data/catalog_providers.dart';
import '../../../features/catalog/domain/product_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/fcfa_formatter.dart';
import '../../../shared/utils/scan_feedback.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_banner.dart';
import '../data/pos_providers.dart';

void _unawaited(Future<void> f) {}

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _query = '';
  bool _showScanner = false;
  late final MobileScannerController _scanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanner.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (_showScanner) _unawaited(_scanner.stop());
      case AppLifecycleState.resumed:
        if (_showScanner) _unawaited(_scanner.start());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _unawaited(ScanFeedback.beep());
    _unawaited(_scanner.stop());

    final product = await ref
        .read(productRepositoryProvider)
        .getProductByBarcode(code);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Produit introuvable.'),
          backgroundColor: AkomColors.error,
        ),
      );
      _unawaited(_scanner.start());
      return;
    }

    ref.read(cartProvider.notifier).addItem(product);
    setState(() => _showScanner = false);
  }

  List<ProductModel> _filtered(List<ProductModel> all) {
    if (_query.isEmpty) return all;
    return all
        .where((p) =>
            p.name.toLowerCase().contains(_query) ||
            (p.barcode?.contains(_query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse'),
        actions: [
          if (cart.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.shopping_cart, color: AkomColors.onPrimary),
              label: Text(
                formatFCFA(total),
                style: const TextStyle(color: AkomColors.onPrimary),
              ),
              onPressed: () => context.push('/pos/cart'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!isOnline)
            const ErrorBanner(
              message: 'Mode hors ligne — produits depuis le cache local',
              type: ErrorBannerType.offline,
            ),
          if (_showScanner) ...[
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scanner,
                    onDetect: _onDetect,
                  ),
                  Center(
                    child: Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AkomColors.secondary, width: 2),
                        borderRadius: AkomRadius.borderMd,
                      ),
                    ),
                  ),
                  Positioned(
                    top: AkomSpacing.sm,
                    right: AkomSpacing.sm,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        _unawaited(_scanner.stop());
                        setState(() => _showScanner = false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AkomSpacing.md, AkomSpacing.sm, AkomSpacing.md, AkomSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un produit…',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AkomSpacing.sm),
                IconButton.filled(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    setState(() => _showScanner = !_showScanner);
                    if (_showScanner) {
                      _unawaited(_scanner.start());
                    } else {
                      _unawaited(_scanner.stop());
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: _showScanner
                        ? AkomColors.secondary
                        : AkomColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (data) {
                final filtered = _filtered(data.products);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'Aucun produit trouvé',
                    subtitle: _query.isEmpty
                        ? 'Ajoutez des produits dans le catalogue.'
                        : 'Essayez un autre terme de recherche.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _ProductRow(
                      product: product,
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} ajouté au panier'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/pos/cart'),
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('${cart.length} article${cart.length > 1 ? 's' : ''} · ${formatFCFA(total)}'),
            )
          : null,
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: product.imageUrl != null
          ? ClipRRect(
              borderRadius: AkomRadius.borderSm,
              child: CachedNetworkImage(
                imageUrl: product.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    const Icon(Icons.image_not_supported_outlined),
              ),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AkomColors.background,
                borderRadius: AkomRadius.borderSm,
                border: Border.all(color: AkomColors.divider),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.inventory_2_outlined,
                  color: AkomColors.onSurfaceVariant),
            ),
      title: Text(product.name, style: AkomTextStyles.titleMedium),
      subtitle: Text(
        formatFCFA(product.price),
        style: AkomTextStyles.bodySmall
            .copyWith(color: AkomColors.primary, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.add_circle_outline, color: AkomColors.primary),
      onTap: onTap,
    );
  }
}
