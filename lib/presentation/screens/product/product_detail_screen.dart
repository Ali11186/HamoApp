import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/cart_item_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_overlay.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final ProductEntity? product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _imageIndex = 0;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    // Increment view count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productRepositoryProvider).incrementViewCount(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final product = productAsync.value ?? widget.product;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('العرض')),
        body: productAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('العرض غير موجود')),
      );
    }

    final isInCart = ref.watch(cartProvider.notifier).isInCart(product.id);
    final currentUser = ref.watch(currentUserProvider);
    final isSeller = currentUser?.id == product.sellerId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Image Gallery App Bar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            leading: _buildBackButton(context),
            actions: [
              IconButton(
                onPressed: () => Share.share(
                  'شاهد عرض ${product.title} في 𝐇𝐚𝐦𝐨 - ${product.price} جنيه',
                ),
                icon: const Icon(Icons.share_rounded),
              ),
              _buildWishlistButton(product),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(product),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Status
                  Row(
                    children: [
                      _buildChip(AppConstants.categoryLabel(product.category)),
                      const SizedBox(width: 8),
                      if (!product.isInStock)
                        _buildChip('غير متوفر', color: AppColors.error)
                      else if (product.isLowStock)
                        _buildChip('متبقي ${product.stockCount}',
                            color: AppColors.warning),
                      if (product.isSellerVerified) ...[
                        const SizedBox(width: 8),
                        _buildChip('عرض رسمي', color: AppColors.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Text(
                    AppFormatters.formatCurrency(product.price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primaryGradientStart,
                          fontWeight: FontWeight.w900,
                        ),
                  ),

                  const SizedBox(height: 12),

                  const SizedBox(height: 4),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'الوصف',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    firstChild: Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    crossFadeState: _showFullDescription
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  if (product.description.length > 200)
                    TextButton(
                      onPressed: () => setState(
                          () => _showFullDescription = !_showFullDescription),
                      child: Text(
                          _showFullDescription ? 'عرض أقل' : 'قراءة المزيد'),
                    ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Seller Card
                  _buildSellerCard(context, product, isSeller),

                  const SizedBox(height: 16),

                  // Product specs
                  if (product.brand != null || product.condition != null) ...[
                    _buildSpecsSection(context, product),
                    const SizedBox(height: 16),
                  ],

                  // Quantity selector
                  if (!isSeller && product.isInStock)
                    _buildQuantitySelector(context),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar:
          _buildBottomBar(context, product, isInCart, isSeller),
    );
  }

  Widget _buildImageCarousel(ProductEntity product) {
    if (product.imageUrls.isEmpty) {
      return Container(
        color: AppColors.dividerBorder.withOpacity(0.3),
        child: const Icon(Icons.image_outlined,
            size: 80, color: AppColors.textSecondary),
      );
    }

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: product.imageUrls.length,
          itemBuilder: (context, index, _) => GestureDetector(
            onTap: () => _openImageViewer(product.imageUrls, index),
            child: CachedNetworkImage(
              imageUrl: product.imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          options: CarouselOptions(
            height: 320,
            viewportFraction: 1.0,
            onPageChanged: (index, _) => setState(() => _imageIndex = index),
          ),
        ),
        // Image counter
        if (product.imageUrls.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_imageIndex + 1}/${product.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  void _openImageViewer(List<String> images, int initial) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            builder: (_, index) => PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(images[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
            pageController: PageController(initialPage: initial),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildWishlistButton(ProductEntity product) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          onPressed: () {
            final userId = ref.read(currentUserProvider)?.id;
            if (userId != null) {
              ref.read(toggleWishlistUseCaseProvider).call(product.id, userId);
            }
          },
          icon: const Icon(Icons.favorite_border_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildChip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? AppColors.secondaryAccent).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.secondaryAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSellerCard(
      BuildContext context, ProductEntity product, bool isSeller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerBorder, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF6941C6),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('𝐇𝐚𝐦𝐨',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF6941C6), size: 18),
                  ],
                ),
                const Text('الإدارة الرسمية',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (!isSeller)
            TextButton.icon(
              onPressed: () async {
                final currentUser = ref.read(currentUserProvider);
                if (currentUser == null) return;
                final chat = await ref
                    .read(chatNotifierProvider.notifier)
                    .getOrCreateChat(
                      sellerId: AppConstants.adminUid,
                      productTitle: product.title,
                      productImageUrl: product.mainThumbnailUrl,
                    );
                if (chat != null && context.mounted) {
                  context.push('/chat/${chat.id}', extra: {
                    'otherUserName': '𝐇𝐚𝐦𝐨',
                    'otherUserAvatar': null,
                  });
                }
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('تواصل'),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecsSection(BuildContext context, ProductEntity product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المواصفات',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (product.brand != null) _buildSpecRow('الماركة', product.brand!),
          if (product.condition != null)
            _buildSpecRow('الحالة', product.condition!),
          _buildSpecRow('المخزون', product.stockCount.toString()),
          _buildSpecRow('المشاهدات', product.viewCount.toString()),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context) {
    return Row(
      children: [
        Text('الكمية:', style: Theme.of(context).textTheme.titleSmall),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.dividerBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_rounded),
                iconSize: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_quantity',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_rounded),
                iconSize: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ProductEntity product,
    bool isInCart,
    bool isSeller,
  ) {
    if (isSeller) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppButton(
            onPressed: () => context.push(RouteConstants.adminDashboard),
            label: 'إدارة العروض',
            icon: Icons.admin_panel_settings_outlined,
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                onPressed: () => _showOfferRequestDialog(context, product),
                label: 'طلب العرض',
                icon: Icons.shopping_bag_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                onPressed: () async {
                  final currentUser = ref.read(currentUserProvider);
                  if (currentUser == null) return;
                  final chat = await ref
                      .read(chatNotifierProvider.notifier)
                      .getOrCreateChat(
                        sellerId: AppConstants.adminUid,
                        productTitle: product.title,
                        productImageUrl: product.mainThumbnailUrl,
                      );
                  if (chat != null && context.mounted) {
                    context.push('/chat/${chat.id}', extra: {
                      'otherUserName': '𝐇𝐚𝐦𝐨',
                      'otherUserAvatar': null,
                    });
                  }
                },
                label: 'تواصل مع الأدمن',
                icon: Icons.chat_bubble_outline_rounded,
                isOutlined: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOfferRequestDialog(
      BuildContext context, ProductEntity product) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final total = product.price * _quantity;
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryGradientStart.withOpacity(.13),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shopping_bag_rounded,
              color: AppColors.primaryGradientStart, size: 28),
        ),
        title: const Text('طلب العرض', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _requestDetail('العرض', product.title),
              _requestDetail('الكمية', '$_quantity'),
              _requestDetail('الإجمالي', AppFormatters.formatCurrency(total)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withOpacity(.35)),
                ),
                child: const Text(
                  'لازم تحوّل الفلوس للأدمن أولًا قبل التواصل مع الأدمن. بعد التحويل اضغط «تواصل مع الأدمن» وأرسل اسكرين بالمبلغ الذي تم تحويله.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontWeight: FontWeight.w900, height: 1.55),
                ),
              ),
              const SizedBox(height: 14),
              const Text('أرقام كاش الإدارة',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              ...AppConstants.cashNumbers
                  .map((number) => _cashCopyRow(context, number)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.send_rounded),
            label: const Text('إرسال طلب العرض'),
          ),
        ],
      ),
    );
    if (shouldSubmit != true || !mounted) return;
    final item = CartItemEntity(
      productId: product.id,
      title: product.title,
      imageUrl: product.mainThumbnailUrl,
      price: product.price,
      quantity: _quantity,
      maxQuantity: product.stockCount,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
    );
    final result = await ref.read(orderRepositoryProvider).createOfferRequest(
          item: item,
          buyerName: user.fullName,
          phoneNumber: user.phoneNumber ?? '',
          notes:
              'OFFER_REQUEST: ${product.title} | يجب تحويل المبلغ ثم إرسال صورة التحويل للأدمن',
        );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال الطلب: ${failure.message}'))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب العرض للأدمن بنجاح'))),
    );
  }

  Widget _requestDetail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
      );

  Widget _cashCopyRow(BuildContext context, String number) => Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
            color: AppColors.primaryGradientStart.withOpacity(.08),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.phone_android_rounded,
              color: AppColors.secondaryAccent, size: 19),
          const SizedBox(width: 8),
          Expanded(
              child: Text(number,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1))),
          IconButton(
            tooltip: 'نسخ الرقم',
            icon: const Icon(Icons.copy_rounded,
                color: AppColors.secondaryAccent, size: 19),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: number));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ رقم الكاش')));
            },
          ),
        ]),
      );
}
