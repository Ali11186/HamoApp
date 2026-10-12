import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _categoryColors = {
    'اتصالات': Color(0xFF00A651),
    'فودافون': Color(0xFFE31837),
    'فواتير': Color(0xFF1570EF),
  };

  static const _categoryIcons = {
    'اتصالات': Icons.sim_card_rounded,
    'فودافون': Icons.phone_android_rounded,
    'فواتير': Icons.receipt_long_rounded,
  };

  void _openCategory(BuildContext context, String category) {
    context.push('/category/${Uri.encodeComponent(category)}', extra: category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر القسم',
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: AppConstants.productCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final category = AppConstants.productCategories[index];
                    final color = _categoryColors[category] ??
                        AppColors.primaryGradientStart;
                    final icon = _categoryIcons[category] ??
                        Icons.category_rounded;

                    return Semantics(
                      button: true,
                      label: category,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => _openCategory(context, category),
                          child: Ink(
                            height: 116,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: color.withOpacity(.36),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(.10),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(.16),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(icon, color: color, size: 30),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_left_rounded,
                                    size: 30,
                                    color: color,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
