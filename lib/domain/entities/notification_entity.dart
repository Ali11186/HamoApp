import 'package:equatable/equatable.dart';

enum NotificationType { order, chat, system, promo }

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedId; // orderId, chatId, productId, etc.

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.system,
    this.isRead = false,
    required this.createdAt,
    this.relatedId,
  });

  @override
  List<Object?> get props =>
      [id, title, body, type, isRead, createdAt, relatedId];
}
