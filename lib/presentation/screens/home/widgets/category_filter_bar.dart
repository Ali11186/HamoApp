import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class CategoryFilterBar extends StatelessWidget {
  final String? selectedCategory;
  final void Function(String?) onCategorySelected;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const _colors = {
    'اتصالات': Color(0xFF00A651),
    'فودافون': Color(0xFFE31837),
    'فواتير': Color(0xFF1570EF),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: AppConstants.productCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = AppConstants.productCategories[index];
          final selected = selectedCategory == category;
          final color = _colors[category] ?? AppColors.primaryGradientStart;
          return Semantics(
            button: true,
            label: category,
            child: GestureDetector(
              onTap: () => onCategorySelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 104,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? color : color.withOpacity(.25),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BrandMark(
                      category: category,
                      color: selected ? Colors.white : color,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final String category;
  final Color color;

  const _BrandMark({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = switch (category) {
      'اتصالات' => 'e&',
      'فودافون' => 'V',
      'فواتير' => 'فاتورة',
      _ => null,
    };
    if (text != null) {
      return Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: text == 'فاتورة' ? 10 : 23,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Icon(Icons.category_rounded, color: color, size: 25);
  }
}
