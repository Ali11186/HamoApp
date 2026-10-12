import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';

class AdminVerificationsScreen extends ConsumerWidget {
  const AdminVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsProvider = FutureProvider.autoDispose(
      (r) => r.watch(userRepositoryProvider).getPendingVerifications(),
    );
    final usersAsync = ref.watch(verificationsProvider);

    Future<void> respond(UserEntity u, VerificationStatus status) async {
      final result =
          await ref.read(userRepositoryProvider).updateVerificationStatus(
                userId: u.id,
                status: status,
                reason: status == VerificationStatus.rejected
                    ? 'Not approved'
                    : null,
              );
      if (!context.mounted) return;
      result.fold(
        (f) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message))),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${u.fullName}: ${status.name}')),
          );
          ref.invalidate(verificationsProvider);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات التوثيق'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(verificationsProvider),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (result) => result.fold(
          (f) => ErrorStateWidget(message: f.message),
          (users) => users.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.verified_outlined,
                  title: 'No pending verifications')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.dividerBorder.withOpacity(0.5)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(u.businessName ?? 'No business name',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                            if (u.phoneNumber != null)
                              Text(u.phoneNumber!,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                  child: ElevatedButton.icon(
                                onPressed: () =>
                                    respond(u, VerificationStatus.approved),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success),
                              )),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: ElevatedButton.icon(
                                onPressed: () =>
                                    respond(u, VerificationStatus.rejected),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error),
                              )),
                            ]),
                          ]),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
      ),
    );
  }
}
