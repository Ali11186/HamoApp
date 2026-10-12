import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/product_card.dart';

class CategoryOffersScreen extends ConsumerStatefulWidget {
  final String category;
  const CategoryOffersScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryOffersScreen> createState() =>
      _CategoryOffersScreenState();
}

class _CategoryOffersScreenState extends ConsumerState<CategoryOffersScreen> {
  final _scrollController = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = null;
    _scrollController.addListener(() {
      if (_selectedCategory == null) return;
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 220) {
        ref.read(productsProvider.notifier).loadMore();
      }
    });
    // لا نحمل كل المنتجات عند الدخول. نعرض الأقسام الفرعية فقط.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(productsProvider.notifier).clearProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    ref.read(productsProvider.notifier).setCategory(category);
  }

  void _backToSubcategories() {
    setState(() => _selectedCategory = null);
    ref.read(productsProvider.notifier).clearProducts();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final color = _categoryColor(widget.category);
    final subcategories = AppConstants.productSubcategories[widget.category] ??
        const <String, String>{};
    final showProducts = _selectedCategory != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          showProducts
              ? AppConstants.categoryLabel(_selectedCategory!)
              : widget.category,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primaryDark,
        leading: showProducts
            ? IconButton(
                tooltip: 'رجوع للأقسام الفرعية',
                onPressed: _backToSubcategories,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        actions: [
          if (showProducts)
            IconButton(
              tooltip: 'الأقسام الفرعية',
              onPressed: _backToSubcategories,
              icon: const Icon(Icons.apps_rounded),
            ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              if (showProducts) {
                ref.read(productsProvider.notifier).setCategory(
                      _selectedCategory,
                    );
              }
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: color,
        onRefresh: () async {
          if (showProducts) {
            await ref
                .read(productsProvider.notifier)
                .setCategory(_selectedCategory);
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _CategoryHeader(category: widget.category, color: color),
            ),
            SliverToBoxAdapter(
              child: _SubcategorySelector(
                subcategories: subcategories,
                selectedCategory: _selectedCategory,
                color: color,
                onSelected: _selectCategory,
              ),
            ),
            if (!showProducts)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 64, color: color.withOpacity(.7)),
                      const SizedBox(height: 16),
                      Text(
                        'اختر القسم الفرعي',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اضغط على أحد الأقسام بالأعلى لعرض العروض',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (state.isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: 6,
                  itemBuilder: (_, __) => const ProductCardShimmer(),
                ),
              )
            else if (state.error != null)
              SliverFillRemaining(
                child: _ErrorContent(
                  message: state.error!,
                  onRetry: () => ref
                      .read(productsProvider.notifier)
                      .setCategory(_selectedCategory),
                ),
              )
            else if (state.products.isEmpty)
              const SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.local_offer_outlined,
                  title: 'لا توجد عروض في هذا القسم',
                  subtitle: 'سيظهر أي عرض جديد هنا تلقائيًا',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: state.products.length,
                  itemBuilder: (_, index) => ProductCard(
                    product: state.products[index],
                    isGridView: true,
                  ),
                ),
              ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'اتصالات':
      case 'عروض اتصالات':
        return const Color(0xFF00A651);
      case 'فودافون':
      case 'عروض فودافون':
        return const Color(0xFFE31837);
      case 'فواتير':
      case 'دفع الفواتير':
        return const Color(0xFF1570EF);
      default:
        return AppColors.primaryGradientStart;
    }
  }
}

class _SubcategorySelector extends StatelessWidget {
  final Map<String, String> subcategories;
  final String? selectedCategory;
  final Color color;
  final ValueChanged<String> onSelected;

  const _SubcategorySelector({
    required this.subcategories,
    required this.selectedCategory,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sections = subcategories.entries
        .map((entry) => (label: entry.key, value: entry.value))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sections.map((section) {
          final isSelected = selectedCategory == section.value;
          return ChoiceChip(
            label: Text(section.label),
            selected: isSelected,
            selectedColor: color,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            onSelected: (_) => onSelected(section.value),
            side: BorderSide(color: color.withOpacity(.30)),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  final Color color;
  const _CategoryHeader({required this.category, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(.95), color.withOpacity(.55)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.24),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('اختر القسم الفرعي المطلوب',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ]),
      );
}

class _ErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorContent({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 46),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ]),
        ),
      );
}
