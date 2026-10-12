import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/product_entity.dart';

class ProductCard extends ConsumerWidget {
  final ProductEntity product;
  final bool isGridView;
  const ProductCard({super.key, required this.product, this.isGridView = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
        onTap: () => context.push('/product/${product.id}', extra: product),
        child: isGridView ? _grid(context) : _list(context),
      );

  Widget _image({required double width, required double height}) {
    final url = product.mainThumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: url.isEmpty
          ? Container(
              width: width,
              height: height,
              color: AppColors.dividerBorder.withOpacity(.25),
              child: const Icon(Icons.image_outlined,
                  color: AppColors.textSecondary, size: 38))
          : CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  width: width,
                  height: height,
                  color: AppColors.dividerBorder.withOpacity(.25),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))),
              errorWidget: (_, __, ___) => Container(
                  width: width,
                  height: height,
                  color: AppColors.dividerBorder.withOpacity(.25),
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textSecondary)),
            ),
    );
  }

  Widget _brandBadge() {
    final label = AppConstants.categoryLabel(product.category);
    final color = label.contains('اتصالات')
        ? const Color(0xFF00A651)
        : label.contains('فودافون')
            ? const Color(0xFFE31837)
            : label.contains('فواتير')
                ? const Color(0xFF1570EF)
                : const Color(0xFF6941C6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(9)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _availability() => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
            product.isInStock
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 13,
            color: product.isInStock ? AppColors.success : AppColors.error),
        const SizedBox(width: 4),
        Text(product.isInStock ? 'متاح' : 'غير متاح',
            style: TextStyle(
                fontSize: 10,
                color: product.isInStock ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700)),
      ]);

  Widget _grid(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.dividerBorder.withOpacity(.35)),
            boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            AspectRatio(
                aspectRatio: .92,
                child: _image(width: double.infinity, height: double.infinity)),
            Positioned(top: 9, right: 9, child: _brandBadge()),
          ]),
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800, height: 1.25)),
                    const SizedBox(height: 9),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                                  AppFormatters.formatCurrency(product.price),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          color: AppColors.primaryGradientStart,
                                          fontWeight: FontWeight.w900))),
                          _availability()
                        ]),
                  ])),
        ]),
      );

  Widget _list(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.dividerBorder.withOpacity(.35)),
            boxShadow: AppColors.softShadow),
        child: Row(children: [
          _image(width: 112, height: 112),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _brandBadge(),
                const SizedBox(height: 7),
                Text(product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(
                              AppFormatters.formatCurrency(product.price),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      color: AppColors.primaryGradientStart,
                                      fontWeight: FontWeight.w900))),
                      _availability()
                    ]),
              ])),
        ]),
      );
}
