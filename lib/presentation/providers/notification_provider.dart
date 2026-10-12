import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';
import 'auth_provider.dart';
import 'providers.dart';

/// يجمع إشعارات الشات من Supabase مع إشعارات تفعيل الطلبات من Firestore.
final notificationsStreamProvider =
    StreamProvider<List<NotificationEntity>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();

  final chatStream =
      ref.watch(chatRepositoryProvider).watchUserChats(userId).map(
            (chats) => chats
                .where((chat) =>
                    chat.lastMessage != null && chat.lastMessage!.isNotEmpty)
                .map((chat) => NotificationEntity(
                      id: 'chat_${chat.id}',
                      title:
                          'رسالة جديدة من ${chat.getOtherParticipantId(userId) == AppConstants.adminUid ? '𝐇𝐚𝐦𝐨' : 'العميل'}',
                      body: chat.lastMessage ?? '',
                      type: NotificationType.chat,
                      isRead: chat.lastMessageSenderId == userId,
                      createdAt: chat.lastMessageAt ?? chat.createdAt,
                      relatedId: chat.id,
                    ))
                .toList(),
          );

  final orderStream = FirebaseFirestore.instance
      .collection('notifications')
      .doc(userId)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map(NotificationModel.fromFirestore).toList());

  return Stream.multi((controller) {
    var chats = <NotificationEntity>[];
    var orders = <NotificationEntity>[];

    void emit() {
      final all = [...chats, ...orders]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(all);
    }

    final chatSubscription = chatStream.listen((value) {
      chats = value;
      emit();
    }, onError: controller.addError);
    final orderSubscription = orderStream.listen((value) {
      orders = value;
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await chatSubscription.cancel();
      await orderSubscription.cancel();
    };
  });
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

class NotificationActions {
  final Ref _ref;
  const NotificationActions(this._ref);

  Future<void> markAsRead(String notificationId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    if (notificationId.startsWith('order_')) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({'isRead': true});
      return;
    }
    if (!notificationId.startsWith('chat_')) return;
    await _ref
        .read(chatRepositoryProvider)
        .markMessagesAsRead(notificationId.substring(5), userId);
  }

  Future<void> markAllAsRead() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    final notificationRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('items');
    final snapshot =
        await notificationRef.where('isRead', isEqualTo: false).get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
    final result = await _ref.read(chatRepositoryProvider).getUserChats(userId);
    await result.fold<Future<void>>(
      (_) async {},
      (chats) async {
        for (final chat in chats) {
          await _ref
              .read(chatRepositoryProvider)
              .markMessagesAsRead(chat.id, userId);
        }
      },
    );
  }

  Future<void> delete(String notificationId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null || !notificationId.startsWith('order_')) return;
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .doc(notificationId)
        .delete();
  }
}

final notificationActionsProvider = Provider((ref) => NotificationActions(ref));
