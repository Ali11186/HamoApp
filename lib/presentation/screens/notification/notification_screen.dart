import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/loading_overlay.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) => list.any((n) => !n.isRead)
                ? TextButton(
                    onPressed: () =>
                        ref.read(notificationActionsProvider).markAllAsRead(),
                    child: const Text('تحديد الكل كمقروء',
                        style: TextStyle(color: Colors.white)),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل الإشعارات',
          subtitle: 'اسحب لأسفل للمحاولة مرة أخرى',
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'لا توجد إشعارات',
              subtitle: 'ستظهر هنا رسائل المحادثات والتحديثات الجديدة',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) =>
                    ref.read(notificationActionsProvider).delete(n.id),
                child: ListTile(
                  tileColor: n.isRead
                      ? null
                      : AppColors.primaryGradientStart.withOpacity(0.06),
                  leading: CircleAvatar(
                    backgroundColor: _iconColor(n.type).withOpacity(0.12),
                    child: Icon(_iconFor(n.type),
                        color: _iconColor(n.type), size: 20),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                        fontWeight:
                            n.isRead ? FontWeight.w500 : FontWeight.w700),
                  ),
                  subtitle: Text(n.body,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    _timeAgo(n.createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    ref.read(notificationActionsProvider).markAsRead(n.id);
                    _handleTap(context, n);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, NotificationEntity n) {
    if (n.relatedId == null) return;
    switch (n.type) {
      case NotificationType.chat:
        context.push('/chat/${n.relatedId}');
        break;
      case NotificationType.order:
        context.push('/order/${n.relatedId}');
        break;
      default:
        break;
    }
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag_outlined;
      case NotificationType.chat:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.secondaryAccent;
      case NotificationType.chat:
        return AppColors.primaryGradientStart;
      case NotificationType.promo:
        return AppColors.notificationYellow;
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.day}/${date.month}';
  }
}
