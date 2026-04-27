import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/akom_button.dart';
import '../../../shared/widgets/akom_text_field.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../data/catalog_providers.dart';
import '../domain/product_draft.dart';
import '../domain/product_model.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({
    super.key,
    this.product,
    this.initialDraft,
  });

  /// Non-null → mode édition
  final ProductModel? product;

  /// Pré-remplissage depuis le scanner ou Open Food Facts
  final ProductDraft? initialDraft;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _barcodeCtrl;

  String? _selectedCategoryId;
  String? _imageUrl;
  String? _localImagePath;
  bool _isLoading = false;
  String? _error;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final d = widget.initialDraft;
    _nameCtrl = TextEditingController(
        text: p?.name ?? d?.name ?? '');
    _descCtrl = TextEditingController(
        text: p?.description ?? d?.description ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? '${p.price}' : (d?.price != 0 ? '${d?.price ?? ''}' : ''));
    _barcodeCtrl = TextEditingController(
        text: p?.barcode ?? d?.barcode ?? '');
    _selectedCategoryId = p?.categoryId ?? d?.categoryId;
    _imageUrl = p?.imageUrl ?? d?.imageUrl;
    _localImagePath = d?.localImagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  ProductDraft _buildDraft() => ProductDraft(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: int.tryParse(_priceCtrl.text.trim()) ?? 0,
        categoryId: _selectedCategoryId,
        barcode: _barcodeCtrl.text.trim().isEmpty
            ? null
            : _barcodeCtrl.text.trim(),
        imageUrl: _imageUrl,
        localImagePath: _localImagePath,
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final draft = _buildDraft();
      final repo = ref.read(productRepositoryProvider);
      late ProductModel saved;

      if (_isEdit) {
        saved = await repo.updateProduct(widget.product!.id, draft);
        ref.read(productsProvider.notifier).replace(saved);
        if (mounted) context.pop();
      } else {
        saved = await repo.createProduct(draft);
        ref.read(productsProvider.notifier).prepend(saved);
        if (!mounted) return;
        // Si pas de code-barres → proposer d'imprimer l'étiquette QR
        if (draft.barcode == null || draft.barcode!.isEmpty) {
          context.pushReplacement(
            '/catalog/product/${saved.id}/qr',
            extra: saved,
          );
        } else {
          context.pop();
        }
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await _imageSourceDialog();
    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file != null && mounted) {
      setState(() {
        _localImagePath = file.path;
        _imageUrl = null;
      });
    }
  }

  Future<ImageSource?> _imageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir une source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le produit' : 'Nouveau produit'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isEdit ? 'Mise à jour…' : 'Création…',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AkomSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  ErrorBanner.error(message: _error!),
                  const SizedBox(height: AkomSpacing.md),
                ],
                _ImagePicker(
                  imageUrl: _imageUrl,
                  localImagePath: _localImagePath,
                  onTap: _pickImage,
                ),
                const SizedBox(height: AkomSpacing.md),
                AkomTextField(
                  controller: _nameCtrl,
                  label: 'Nom du produit *',
                  hint: 'Ex: Eau minérale 1.5L',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Le nom est obligatoire'
                      : null,
                ),
                const SizedBox(height: AkomSpacing.md),
                AkomTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Description courte (optionnel)',
                  maxLines: 2,
                ),
                const SizedBox(height: AkomSpacing.md),
                AkomTextField(
                  controller: _priceCtrl,
                  label: 'Prix (FCFA) *',
                  hint: 'Ex: 500',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Le prix est obligatoire';
                    final p = int.tryParse(v.trim());
                    if (p == null || p <= 0) return 'Prix invalide';
                    return null;
                  },
                ),
                const SizedBox(height: AkomSpacing.md),
                // Dropdown catégorie
                categoriesAsync.when(
                  data: (cats) => _CategoryDropdown(
                    categories: cats,
                    value: _selectedCategoryId,
                    onChanged: (id) =>
                        setState(() => _selectedCategoryId = id),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AkomSpacing.md),
                AkomTextField(
                  controller: _barcodeCtrl,
                  label: 'Code-barres',
                  hint: 'Optionnel — laissez vide pour générer un QR',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AkomSpacing.xl),
                AkomButton(
                  label: _isEdit ? 'Enregistrer les modifications' : 'Créer le produit',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AkomSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.imageUrl,
    required this.localImagePath,
    required this.onTap,
  });

  final String? imageUrl;
  final String? localImagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (localImagePath != null) {
      imageWidget = Image.file(File(localImagePath!), fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = Image.network(imageUrl!, fit: BoxFit.cover);
    } else {
      imageWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              size: 40, color: AkomColors.onSurfaceVariant),
          const SizedBox(height: AkomSpacing.sm),
          Text('Ajouter une photo',
              style: AkomTextStyles.bodySmall),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AkomColors.background,
          border: Border.all(color: AkomColors.divider),
          borderRadius: AkomRadius.borderMd,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageWidget,
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<dynamic> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Catégorie',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      hint: const Text('Choisir une catégorie'),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Sans catégorie'),
        ),
        ...categories.map((c) => DropdownMenuItem<String>(
              value: c.id as String,
              child: Text(c.name as String),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
