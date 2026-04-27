import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/fcfa_formatter.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    this.categoryName,
    this.stock,
    this.stockThreshold,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final String name;
  final int price;
  final String? imageUrl;
  final String? categoryName;
  final int? stock;
  final int? stockThreshold;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AkomRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.all(AkomSpacing.md),
          child: Row(
            children: [
              _ProductImage(url: imageUrl, name: name),
              const SizedBox(width: AkomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AkomTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (categoryName != null) ...[
                      const SizedBox(height: AkomSpacing.xs),
                      Text(
                        categoryName!,
                        style: AkomTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AkomSpacing.sm),
                    Row(
                      children: [
                        Text(
                          formatFCFA(price),
                          style: AkomTextStyles.price,
                        ),
                        if (stock != null) ...[
                          const SizedBox(width: AkomSpacing.md),
                          _StockBadge(
                            stock: stock!,
                            threshold: stockThreshold,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AkomSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    const radius = AkomRadius.borderSm;

    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => _Placeholder(name: name, size: size),
          errorWidget: (_, _, _) => _Placeholder(name: name, size: size),
        ),
      );
    }

    return _Placeholder(name: name, size: size);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AkomColors.primary.withAlpha(26),
        borderRadius: AkomRadius.borderSm,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AkomTextStyles.headlineMedium.copyWith(
          color: AkomColors.primary,
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock, this.threshold});

  final int stock;
  final int? threshold;

  @override
  Widget build(BuildContext context) {
    final isLow = threshold != null && stock <= threshold!;
    final isOut = stock <= 0;

    final (bgColor, textColor, label) = switch (true) {
      _ when isOut => (
          AkomColors.errorLight,
          AkomColors.error,
          'Rupture'
        ),
      _ when isLow => (
          AkomColors.warningLight,
          AkomColors.warning,
          'Stock: $stock'
        ),
      _ => (
          AkomColors.successLight,
          AkomColors.success,
          'Stock: $stock'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AkomSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AkomRadius.borderFull,
      ),
      child: Text(
        label,
        style: AkomTextStyles.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
