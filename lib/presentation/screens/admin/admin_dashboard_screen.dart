import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة إدارة 𝐇𝐚𝐦𝐨'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminCard(
              icon: Icons.people_outline_rounded,
              title: 'المستخدمون',
              subtitle: 'عرض وإدارة عملاء المتجر',
              onTap: () => context.push(RouteConstants.adminUsers)),
          _AdminCard(
              icon: Icons.campaign_outlined,
              title: 'نشر عرض جديد',
              subtitle: 'اختر الشركة والقسم الفرعي قبل النشر',
              onTap: () => context.push(RouteConstants.productCreate)),
          _AdminCard(
              icon: Icons.inventory_2_outlined,
              title: 'إدارة العروض',
              subtitle: 'تعديل أو إخفاء العروض المنشورة',
              onTap: () => context.push(RouteConstants.sellerProducts)),
          _AdminCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'رسائل العملاء',
              subtitle: 'افتح المحادثات ورد على العملاء',
              onTap: () => context.push(RouteConstants.chatList)),
          _AdminCard(
              icon: Icons.receipt_long_outlined,
              title: 'الطلبات',
              subtitle: 'متابعة جميع طلبات المتجر',
              onTap: () => context.push(RouteConstants.adminOrders)),
          _AdminCard(
              icon: Icons.verified_outlined,
              title: 'طلبات التوثيق',
              subtitle: 'مراجعة طلبات توثيق البائعين',
              onTap: () => context.push(RouteConstants.adminVerifications)),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AdminCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.primaryGradientStart.withOpacity(.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon,
                      color: AppColors.primaryGradientStart, size: 27)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12))
                  ])),
              const Icon(Icons.chevron_left_rounded,
                  color: AppColors.textSecondary),
            ]),
          ),
        ),
      );
}
