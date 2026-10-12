import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/product_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';

class ProductEditScreen extends ConsumerStatefulWidget {
  final String productId;
  final ProductEntity? product;
  const ProductEditScreen({super.key, required this.productId, this.product});
  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  String _category = AppConstants.defaultProductCategory;
  List<String> _existingImages = [];
  List<File> _newImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toStringAsFixed(2) ?? '');
    _stockCtrl = TextEditingController(text: p?.stockCount.toString() ?? '');
    _category = AppConstants.editableProductCategory(
        p?.category ?? AppConstants.defaultProductCategory);
    _existingImages = List.from(p?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickNewImages() async {
    final picked =
        await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1600);
    if (picked.isNotEmpty) {
      setState(() => _newImages = picked.map((x) => File(x.path)).toList());
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(updateProductUseCaseProvider).call(
            productId: widget.productId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: double.parse(_priceCtrl.text),
            stockCount: int.parse(_stockCtrl.text),
            category: _category,
            newImages: _newImages.isNotEmpty ? _newImages : null,
            existingImageUrls: _existingImages,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      await result.fold<Future<void>>(
        (f) async => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر حفظ التعديل: ${f.message}'))),
        (_) async {
          await ref.read(productsProvider.notifier).loadProducts(refresh: true);
          final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
          if (userId != null) ref.invalidate(sellerProductsProvider(userId));
          if (mounted) context.pop();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر حفظ التعديل: $e')));
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (_isLoading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.error.withOpacity(.14), shape: BoxShape.circle),
          child: const Icon(Icons.delete_forever_rounded,
              color: AppColors.error, size: 30),
        ),
        title: const Text('حذف الإعلان؟'),
        content: const Text(
            'سيتم حذف الإعلان نهائيًا من قاعدة البيانات ولن يمكن استرجاعه بعد التأكيد.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف الإعلان'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final result =
          await ref.read(deleteProductUseCaseProvider).call(widget.productId);
      if (!mounted) return;
      setState(() => _isLoading = false);
      await result.fold<Future<void>>(
        (failure) async => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حذف الإعلان: ${failure.message}')),
        ),
        (_) async {
          await ref.read(productsProvider.notifier).loadProducts(refresh: true);
          final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
          if (userId != null) ref.invalidate(sellerProductsProvider(userId));
          if (mounted) context.pop();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر حذف الإعلان: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = [...AppConstants.productSubcategoryValues];
    if (!categoryOptions.contains(_category)) categoryOptions.insert(0, _category);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('تعديل العرض'),
            backgroundColor: AppColors.primaryDark),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_existingImages.isNotEmpty)
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImages.length,
                          itemBuilder: (_, i) => Stack(children: [
                            Padding(
                                padding:
                                    const EdgeInsets.only(right: 8, top: 8),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                        imageUrl: _existingImages[i],
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover))),
                            Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                    onTap: () => setState(
                                        () => _existingImages.removeAt(i)),
                                    child: Container(
                                        decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close_rounded,
                                            color: Colors.white, size: 16)))),
                          ]),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _pickNewImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_newImages.isEmpty
                          ? 'إضافة صور جديدة'
                          : 'تم اختيار ${_newImages.length} صور'),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _titleCtrl,
                        label: 'عنوان العرض',
                        prefixIcon: Icons.title_rounded,
                        validator: AppValidators.validateProductTitle),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _descCtrl,
                        label: 'الوصف',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 4,
                        validator: AppValidators.validateDescription),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _category,
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: 'قسم العرض',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12))),
                      items: categoryOptions
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(
                                  AppConstants.productCategoryOptionLabel(
                                      category),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _category = value ?? _category),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: AppTextField(
                              controller: _priceCtrl,
                              label: 'السعر (جنيه)',
                              prefixIcon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                              validator: AppValidators.validatePrice)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: AppTextField(
                              controller: _stockCtrl,
                              label: 'الكمية',
                              prefixIcon: Icons.inventory_2_outlined,
                              keyboardType: TextInputType.number,
                              validator: AppValidators.validateStockCount)),
                    ]),
                    const SizedBox(height: 24),
                    AppButton(
                        onPressed: _submit,
                        label: 'حفظ التعديلات',
                        isLoading: _isLoading),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deleteProduct,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('حذف الإعلان'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ])),
        ),
      ),
    );
  }
}
