import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_logo_text.dart';
import '../../widgets/loading_overlay.dart';
import '../../../core/constants/route_constants.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authProvider.notifier).signUp(
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go(RouteConstants.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: AppColors.backgroundMain,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: GradientLogoText(fontSize: 32)),
                const SizedBox(height: 24),

                Text(
                  'إنشاء حساب',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'انضم إلى 𝐇𝐚𝐦𝐨 الآن',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: 24),

                // Error
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(authState.errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'الاسم الكامل',
                        hint: 'اسمك بالكامل',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: AppValidators.validateFullName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        hint: '01xxxxxxxxx',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: AppValidators.validateEgyptianPhone,
                        textInputAction: TextInputAction.next,
                        prefixWidget: _buildPhonePrefix(),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '8 أحرف على الأقل',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        validator: AppValidators.validatePassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'تأكيد كلمة المرور',
                        hint: 'أعد كتابة كلمة المرور',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirm,
                        validator: (v) => AppValidators.validateConfirmPassword(
                            v, _passwordController.text),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                AppButton(
                  onPressed: _register,
                  label: 'إنشاء الحساب',
                  isLoading: isLoading,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('لديك حساب بالفعل؟ ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            )),
                    TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'تسجيل الدخول',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryGradientStart,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhonePrefix() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🇪🇬', style: TextStyle(fontSize: 18)),
        SizedBox(width: 6),
        Text('+20',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        SizedBox(width: 4),
      ],
    );
  }
}
