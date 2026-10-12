import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/product_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';

class ProductCreateScreen extends ConsumerStatefulWidget {
  const ProductCreateScreen({super.key});
  @override
  ConsumerState<ProductCreateScreen> createState() =>
      _ProductCreateScreenState();
}

class _ProductCreateScreenState extends ConsumerState<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  String _category = AppConstants.defaultProductCategory;
  List<File> _images = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (result.isNotEmpty) {
      setState(() => _images = result
          .take(AppConstants.maxProductImages)
          .map((x) => File(x.path))
          .toList());
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أضف صورة واحدة على الأقل')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(createProductUseCaseProvider).call(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: double.parse(_priceCtrl.text),
            category: _category,
            images: _images,
            stockCount: int.parse(_stockCtrl.text),
            brand: _brandCtrl.text.trim().isNotEmpty
                ? _brandCtrl.text.trim()
                : null,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      await result.fold<Future<void>>(
        (f) async {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تعذر نشر العرض: ${f.message}')));
        },
        (_) async {
          await ref.read(productsProvider.notifier).loadProducts(refresh: true);
          final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
          if (userId != null) ref.invalidate(sellerProductsProvider(userId));
          await _showCreatedDialog();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر نشر العرض: $e')));
      }
    }
  }

  Future<void> _showCreatedDialog() async {
    final addAnother = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تم نشر العرض بنجاح'),
        content: const Text(
            'هل تريد إضافة عرض آخر؟ يمكنك نشر عدد غير محدود من العروض.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('العودة للقائمة')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('إضافة عرض آخر')),
        ],
      ),
    );
    if (!mounted) return;
    if (addAnother == true) {
      _titleCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _stockCtrl.clear();
      _brandCtrl.clear();
      setState(() => _images = []);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'جاري نشر العرض...',
      child: Scaffold(
        appBar: AppBar(
            title: const Text('إضافة عرض'),
            backgroundColor: AppColors.primaryDark),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.dividerBorder.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.dividerBorder,
                              style: BorderStyle.solid),
                        ),
                        child: _images.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: AppColors.textSecondary),
                                    SizedBox(height: 8),
                                    Text('اضغط لإضافة صور العرض',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                  ])
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
                                itemCount: _images.length,
                                itemBuilder: (_, i) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(_images[i],
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover))),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                        controller: _titleCtrl,
                        label: 'عنوان العرض',
                        prefixIcon: Icons.title_rounded,
                        validator: AppValidators.validateProductTitle),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _descCtrl,
                        label: 'وصف العرض',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 4,
                        validator: AppValidators.validateDescription),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                          labelText: 'تصنيف العرض',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12))),
                      isExpanded: true,
                      items: AppConstants.productSubcategoryValues
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(
                                  AppConstants.productCategoryOptionLabel(
                                      category),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
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
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _brandCtrl,
                        label: 'الماركة (اختياري)',
                        prefixIcon: Icons.branding_watermark_outlined),
                    const SizedBox(height: 24),
                    AppButton(
                        onPressed: _submit,
                        label: 'نشر العرض',
                        isLoading: _isLoading,
                        icon: Icons.publish_rounded),
                    const SizedBox(height: 32),
                  ])),
        ),
      ),
    );
  }
}
