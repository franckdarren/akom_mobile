import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/product_tile.dart';
import '../data/catalog_providers.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          if (!isOnline)
            const ErrorBanner(
              message: 'Mode hors ligne — données en cache',
              type: ErrorBannerType.offline,
            ),
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          categoriesAsync.when(
            data: (cats) => _CategoryChips(
              categories: cats,
              selected: _selectedCategoryId,
              onSelect: (id) =>
                  setState(() => _selectedCategoryId = id),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: InlineLoader()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AkomColors.error),
                    const SizedBox(height: AkomSpacing.md),
                    Text(error.toString(),
                        style: AkomTextStyles.bodyMedium
                            .copyWith(color: AkomColors.error),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AkomSpacing.lg),
                    TextButton(
                      onPressed: () =>
                          ref.read(productsProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (data) {
                final filtered = _filter(data.products,
                    categoriesAsync.valueOrNull ?? []);
                if (filtered.isEmpty && _searchQuery.isEmpty &&
                    _selectedCategoryId == null) {
                  return EmptyState.products(
                    onAdd: () => _showAddOptions(context),
                  );
                }
                if (filtered.isEmpty) {
                  return EmptyState.search(query: _searchQuery);
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(productsProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AkomSpacing.md),
                    itemCount:
                        filtered.length + (data.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AkomSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AkomSpacing.lg),
                            child: InlineLoader(),
                          ),
                        );
                      }
                      final product = filtered[index];
                      final catName = _categoryName(
                        product.categoryId,
                        categoriesAsync.valueOrNull ?? [],
                      );
                      return ProductTile(
                        name: product.name,
                        price: product.price,
                        imageUrl: product.imageUrl,
                        categoryName: catName,
                        stock: product.stock,
                        onTap: () => _openEdit(context, product),
                        trailing: IconButton(
                          icon: const Icon(Icons.qr_code,
                              color: AkomColors.onSurfaceVariant),
                          tooltip: 'Étiquette QR',
                          onPressed: () => _openQr(context, product),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ProductModel> _filter(
      List<ProductModel> products, List<CategoryModel> categories) {
    return products.where((p) {
      final q = _searchQuery.toLowerCase().trim();
      final matchSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          (p.barcode?.contains(q) ?? false);
      final matchCat =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchSearch && matchCat;
    }).toList();
  }

  String? _categoryName(String? id, List<CategoryModel> cats) {
    if (id == null) return null;
    try {
      return cats.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return null;
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AkomRadius.lg),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AkomSpacing.sm),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scanner un code-barres'),
              onTap: () {
                Navigator.pop(context);
                context.push('/catalog/scanner');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Saisie manuelle'),
              onTap: () {
                Navigator.pop(context);
                context.push('/catalog/new');
              },
            ),
            const SizedBox(height: AkomSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, ProductModel product) {
    context.push('/catalog/product/${product.id}/edit', extra: product);
  }

  void _openQr(BuildContext context, ProductModel product) {
    context.push('/catalog/product/${product.id}/qr', extra: product);
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AkomSpacing.md, AkomSpacing.md, AkomSpacing.md, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<CategoryModel> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AkomSpacing.md, vertical: AkomSpacing.sm),
        children: [
          _Chip(
            label: 'Tous',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
            (c) => _Chip(
              label: c.name,
              selected: selected == c.id,
              onTap: () => onSelect(c.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AkomSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AkomColors.primary.withAlpha(26),
        checkmarkColor: AkomColors.primary,
        labelStyle: AkomTextStyles.bodySmall.copyWith(
          color: selected ? AkomColors.primary : AkomColors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
