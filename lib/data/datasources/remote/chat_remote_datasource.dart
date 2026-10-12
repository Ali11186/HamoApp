import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/services/cloudinary_upload_service.dart';
import '../../../domain/entities/message_entity.dart';
import '../../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatModel> getOrCreateChat(
      {required String buyerId,
      required String sellerId,
      String? productId,
      String? productTitle,
      String? productImageUrl});
  Future<ChatModel> getChatById(String chatId);
  Future<List<ChatModel>> getUserChats(String userId);
  Future<MessageModel> sendMessage(
      {required String chatId,
      required String content,
      MessageType type,
      String? replyToMessageId,
      String? replyToContent});
  Future<MessageModel> sendImageMessage(
      {required String chatId, required File image});
  Future<void> markMessagesAsRead(String chatId, String userId);
  Future<void> deleteChat(String chatId);
  Stream<List<MessageModel>> watchMessages(String chatId);
  Stream<List<ChatModel>> watchUserChats(String userId);
  Stream<int> watchTotalUnreadCount(String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _supabase;
  final CloudinaryUploadService _cloudinary;
  final FirebaseAuth _auth;

  ChatRemoteDataSourceImpl(
      {required SupabaseClient supabase,
      required CloudinaryUploadService cloudinary,
      required FirebaseAuth auth})
      : _supabase = supabase,
        _cloudinary = cloudinary,
        _auth = auth;

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  String _chatId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  ChatModel _chatFromRow(Map<String, dynamic> row) {
    final customerId = row['customer_id'] as String? ?? '';
    final adminId = row['admin_id'] as String? ?? '';
    return ChatModel.fromMap({
      'participantIds': [customerId, adminId],
      'participantNames': {customerId: 'العميل', adminId: 'الإدارة'},
      'participantAvatars': {customerId: null, adminId: null},
      'lastMessage': row['last_message'],
      'lastMessageType': row['last_message_type'],
      'lastMessageSenderId': row['last_message_sender_id'],
      'lastMessageAt': row['updated_at'],
      'unreadCounts': {customerId: 0, adminId: 0},
      'productId': row['product_id'],
      'productTitle': row['product_title'],
      'createdAt': row['created_at'],
      'isActive': true,
    }, row['id'].toString());
  }

  MessageModel _messageFromRow(Map<String, dynamic> row) {
    final senderId = row['sender_id'] as String? ?? '';
    final currentId = _auth.currentUser?.uid;
    return MessageModel.fromMap({
      'chatId': row['conversation_id']?.toString() ?? '',
      'senderId': senderId,
      'senderName': senderId == currentId
          ? (_auth.currentUser?.displayName ?? 'المستخدم')
          : 'الإدارة',
      'content': row['content'] as String? ?? '',
      'type': row['message_type'] as String? ?? 'text',
      'createdAt': row['created_at'],
      'isRead': row['is_read'] as bool? ?? false,
      'imageUrl':
          (row['message_type'] == 'image') ? row['content'] as String? : null,
    }, row['id'].toString());
  }

  @override
  Future<ChatModel> getOrCreateChat(
      {required String buyerId,
      required String sellerId,
      String? productId,
      String? productTitle,
      String? productImageUrl}) async {
    try {
      final existing = await _supabase
          .from('conversations')
          .select()
          .eq('customer_id', buyerId)
          .eq('admin_id', sellerId)
          .maybeSingle();
      if (existing != null) return _chatFromRow(_map(existing));
      final inserted = await _supabase
          .from('conversations')
          .insert({
            'customer_id': buyerId,
            'admin_id': sellerId,
            'product_id': productId,
            'product_title': productTitle,
          })
          .select()
          .single();
      return _chatFromRow(_map(inserted));
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    }
  }

  @override
  Future<ChatModel> getChatById(String chatId) async {
    try {
      final row = await _supabase
          .from('conversations')
          .select()
          .eq('id', chatId)
          .single();
      return _chatFromRow(_map(row));
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    }
  }

  @override
  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      final rows = await _supabase
          .from('conversations')
          .select()
          .or('customer_id.eq.$userId,admin_id.eq.$userId')
          .order('updated_at', ascending: false);
      return (rows as List).map((row) => _chatFromRow(_map(row))).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    }
  }

  Future<List<MessageModel>> _getMessages(String chatId) async {
    final rows = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', chatId)
        .order('created_at', ascending: true);
    return (rows as List).map((row) => _messageFromRow(_map(row))).toList();
  }

  @override
  Future<MessageModel> sendMessage(
      {required String chatId,
      required String content,
      MessageType type = MessageType.text,
      String? replyToMessageId,
      String? replyToContent}) async {
    final user = _auth.currentUser;
    if (user == null)
      throw const AuthException(message: 'يجب تسجيل الدخول أولًا');
    try {
      final row = await _supabase
          .from('messages')
          .insert({
            'conversation_id': chatId,
            'sender_id': user.uid,
            'content': content,
            'message_type': type.name,
            'is_read': false,
          })
          .select()
          .single();
      await _supabase.from('conversations').update({
        'last_message': type == MessageType.image ? 'صورة' : content,
        'last_message_type': type.name,
        'last_message_sender_id': user.uid,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
      return _messageFromRow(_map(row));
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    }
  }

  @override
  Future<MessageModel> sendImageMessage(
      {required String chatId, required File image}) async {
    final url = await _cloudinary.uploadImage(image, folder: 'chats/$chatId');
    return sendMessage(chatId: chatId, content: url, type: MessageType.image);
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', chatId)
          .neq('sender_id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    if (_auth.currentUser?.uid != AppConstants.adminUid) {
      throw const ServerException(message: 'حذف المحادثات متاح للإدارة فقط');
    }
    try {
      // الحذف يتم داخل transaction في Supabase حتى لا تبقى رسائل معلقة
      // إذا نجح حذف أحد الجدولين وفشل الآخر.
      await _supabase.rpc('delete_conversation_for_admin', params: {
        'p_chat_id': chatId,
        'p_admin_uid': AppConstants.adminUid,
      });
    } on PostgrestException catch (e) {
      throw ServerException(
        message: 'تعذر حذف المحادثة من Supabase: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    late final StreamController<List<MessageModel>> controller;
    final channel = _supabase
        .channel('messages-$chatId-${DateTime.now().microsecondsSinceEpoch}');
    controller = StreamController<List<MessageModel>>.broadcast(
      onListen: () async {
        try {
          controller.add(await _getMessages(chatId));
          channel
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'messages',
                filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'conversation_id',
                    value: chatId),
                callback: (_) async {
                  if (!controller.isClosed)
                    controller.add(await _getMessages(chatId));
                },
              )
              .subscribe();
        } catch (e, stack) {
          if (!controller.isClosed) controller.addError(e, stack);
        }
      },
      onCancel: () async {
        await _supabase.removeChannel(channel);
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<ChatModel>> watchUserChats(String userId) {
    late final StreamController<List<ChatModel>> controller;
    final channel = _supabase.channel(
        'conversations-$userId-${DateTime.now().microsecondsSinceEpoch}');
    Future<void> refresh() async {
      try {
        if (!controller.isClosed) controller.add(await getUserChats(userId));
      } catch (e, stack) {
        if (!controller.isClosed) controller.addError(e, stack);
      }
    }

    controller = StreamController<List<ChatModel>>.broadcast(
      onListen: () {
        refresh();
        channel
            .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'conversations',
                callback: (_) => refresh())
            .subscribe();
      },
      onCancel: () async {
        await _supabase.removeChannel(channel);
      },
    );
    return controller.stream;
  }

  @override
  Stream<int> watchTotalUnreadCount(String userId) =>
      watchUserChats(userId).map((chats) =>
          chats.fold(0, (sum, chat) => sum + chat.getUnreadCount(userId)));
}
