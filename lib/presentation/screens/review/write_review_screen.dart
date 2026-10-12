import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String productId;
  final String productTitle;
  const WriteReviewScreen(
      {super.key,
      required this.orderId,
      required this.productId,
      required this.productTitle});
  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await ref.read(submitReviewUseCaseProvider).call(
          productId: widget.productId, orderId: widget.orderId,
          // المراجعة أصبحت نصية فقط؛ نرسل قيمة محايدة للتوافق مع البيانات القديمة.
          rating: 0.0, reviewText: _reviewCtrl.text.trim(),
        );
    setState(() => _isLoading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Review submitted!')));
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Write Review'),
            backgroundColor: AppColors.primaryDark),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.productTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    const Text('شارك رأيك',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _reviewCtrl,
                        label: 'المراجعة',
                        hint: 'اكتب تجربتك مع هذا العرض...',
                        prefixIcon: Icons.rate_review_outlined,
                        maxLines: 5,
                        validator: (v) => v?.trim().isEmpty == true
                            ? 'من فضلك اكتب مراجعتك'
                            : null),
                    const SizedBox(height: 32),
                    AppButton(
                        onPressed: _submit,
                        label: 'Submit Review',
                        isLoading: _isLoading,
                        icon: Icons.send_rounded),
                  ])),
        ),
      ),
    );
  }
}
