import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    super.type,
    super.isRead,
    required super.createdAt,
    super.relatedId,
  });

  factory NotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedId: data['relatedId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'type': type.name,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'relatedId': relatedId,
      };

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'order':
        return NotificationType.order;
      case 'chat':
        return NotificationType.chat;
      case 'promo':
        return NotificationType.promo;
      default:
        return NotificationType.system;
    }
  }
}
