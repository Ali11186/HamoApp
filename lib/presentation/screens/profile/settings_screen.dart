import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/nova_assistant_fab.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('الإعدادات'),
          backgroundColor: AppColors.primaryDark),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminCashCard(),
          const SizedBox(height: 16),
          _Section('المظهر', children: [
            SwitchListTile(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggleTheme(),
              title: const Text('الوضع الداكن'),
              subtitle: const Text('مظهر مريح للعين وموفر للطاقة'),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
          ]),
          const SizedBox(height: 16),
          _Section('الإشعارات', children: [
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('تحديثات الطلبات'),
              secondary: const Icon(Icons.shopping_bag_outlined),
            ),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('رسائل الشات'),
              secondary: const Icon(Icons.chat_bubble_outline_rounded),
            ),
          ]),
          const SizedBox(height: 16),
          _Section('عن التطبيق', children: [
            ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('الإصدار'),
                trailing: const Text('1.0.0')),
            ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('الخصوصية'),
                trailing: const Icon(Icons.chevron_right_rounded)),
            ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('الشروط والأحكام'),
                trailing: const Icon(Icons.chevron_right_rounded)),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, {required this.children});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary))),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerBorder.withOpacity(0.5)),
          ),
          child: Column(children: children),
        ),
      ]);
}
