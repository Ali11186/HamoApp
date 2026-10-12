import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  late final _usersProvider = FutureProvider.autoDispose(
    (r) => r.watch(userRepositoryProvider).getAllUsers(),
  );

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_usersProvider);
    final myUid = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_usersProvider),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (result) => result.fold(
          (f) => ErrorStateWidget(message: f.message),
          (users) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final u = users[i];
              final isMe = u.id == myUid;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.dividerBorder.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryGradientStart,
                        child: Text(
                          u.fullName.isNotEmpty
                              ? u.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(
                                child: Text(u.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                const Text('(you)',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                              ],
                            ]),
                            Text(u.phoneNumber ?? '',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            _RoleBadge(role: u.role),
                          ],
                        ),
                      ),
                      Switch(
                        value: u.isActive,
                        onChanged: isMe
                            ? null
                            : (v) async {
                                await ref
                                    .read(userRepositoryProvider)
                                    .toggleUserActive(u.id, v);
                                ref.invalidate(_usersProvider);
                              },
                        activeColor: AppColors.success,
                      ),
                    ]),
                    const Divider(height: 20),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              isMe ? null : () => _changeRole(context, u),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text('Change role'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              isMe ? null : () => _confirmDelete(context, u),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppColors.error),
                          label: const Text('حذف الرقم',
                              style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
      ),
    );
  }

  Future<void> _changeRole(BuildContext context, UserEntity u) async {
    final role = await showModalBottomSheet<UserRole>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values
              .map((r) => ListTile(
                    leading: Icon(r == u.role
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                    title: Text(r.name.toUpperCase()),
                    onTap: () => Navigator.pop(context, r),
                  ))
              .toList(),
        ),
      ),
    );
    if (role == null || role == u.role || !context.mounted) return;
    final result =
        await ref.read(userRepositoryProvider).setUserRole(u.id, role);
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${u.fullName} is now ${role.name}')),
        );
        ref.invalidate(_usersProvider);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserEntity u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الرقم؟'),
        content: Text(
            'سيتم حذف ملف ${u.fullName} ورقم الهاتف من قاعدة بيانات التطبيق. لا يمكن التراجع عن العملية.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف الرقم',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result =
        await ref.read(userRepositoryProvider).deleteUserProfile(u.id);
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ref.invalidate(_usersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الرقم وملف المستخدم')));
      },
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.admin => AppColors.error,
      UserRole.seller => AppColors.notificationYellow,
      UserRole.buyer => AppColors.secondaryAccent,
    };
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.name.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
