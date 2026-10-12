import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/order_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/loading_overlay.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  late final _ordersProvider = FutureProvider.autoDispose(
    (r) => r.watch(orderRepositoryProvider).getAllOrders(limit: 100),
  );

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(_ordersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات الواردة'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_ordersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (result) => result.fold(
          (f) => ErrorStateWidget(message: f.message),
          (orders) => orders.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.receipt_long_outlined, title: 'No orders yet')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return GestureDetector(
                      onTap: () => context.push('/order/${o.id}'),
                      onLongPress: () => _changeStatus(context, o),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.dividerBorder.withOpacity(0.5)),
                        ),
                        child: Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                if (o.notes?.startsWith('OFFER_REQUEST:') ??
                                    false)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: AppColors.secondaryAccent
                                            .withOpacity(.13),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('طلب عرض جديد',
                                        style: TextStyle(
                                            color: AppColors.secondaryAccent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11)),
                                  ),
                                Text('#${o.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                Text(
                                    '${o.buyerName} · ${AppFormatters.formatDate(o.createdAt)}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ])),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    AppFormatters.formatCurrency(o.totalAmount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryGradientStart)),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _changeStatus(context, o),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: AppColors.primaryGradientStart
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              AppFormatters.formatOrderStatus(
                                                  o.status),
                                              style: const TextStyle(
                                                  color: AppColors
                                                      .primaryGradientStart,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.edit_outlined,
                                              size: 12,
                                              color: AppColors
                                                  .primaryGradientStart),
                                        ]),
                                  ),
                                ),
                                if (o.status != OrderStatus.delivered) ...[
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 32,
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          _markDelivered(context, o),
                                      icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 15),
                                      label: const Text('تم التسليم',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800)),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        backgroundColor: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                                IconButton(
                                  tooltip: 'حذف الطلب',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _deleteOrder(context, o),
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: AppColors.error, size: 20),
                                ),
                              ]),
                        ]),
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

  Future<void> _changeStatus(BuildContext context, OrderEntity o) async {
    final status = await showModalBottomSheet<OrderStatus>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values
              .map((s) => ListTile(
                    leading: Icon(s == o.status
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                    title: Text(AppFormatters.formatOrderStatus(s)),
                    onTap: () => Navigator.pop(context, s),
                  ))
              .toList(),
        ),
      ),
    );
    if (status == null || status == o.status || !context.mounted) return;
    final result = await ref.read(orderRepositoryProvider).updateOrderStatus(
          orderId: o.id,
          status: status,
        );
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Order updated to ${AppFormatters.formatOrderStatus(status)}')),
        );
        ref.invalidate(_ordersProvider);
      },
    );
  }

  Future<void> _markDelivered(BuildContext context, OrderEntity order) async {
    final result = await ref.read(orderRepositoryProvider).updateOrderStatus(
          orderId: order.id,
          status: OrderStatus.delivered,
        );
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم التسليم وإرسال إشعار نجاح التفعيل للعميل')));
        ref.invalidate(_ordersProvider);
      },
    );
  }

  Future<void> _deleteOrder(BuildContext context, OrderEntity order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الطلب؟'),
        content: const Text(
            'سيتم حذف الطلب نهائيًا من لوحة الأدمن. هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result =
        await ref.read(orderRepositoryProvider).deleteOrder(order.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الطلب نهائيًا')));
        ref.invalidate(_ordersProvider);
      },
    );
  }
}
