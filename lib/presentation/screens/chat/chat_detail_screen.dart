import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/message_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserAvatar;
  const ChatDetailScreen(
      {super.key,
      required this.chatId,
      required this.otherUserName,
      this.otherUserAvatar});
  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ref.read(chatNotifierProvider.notifier).markAsRead(widget.chatId));
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _messageCtrl.clear();
    final ok = await ref
        .read(chatNotifierProvider.notifier)
        .sendMessage(widget.chatId, text);
    if (mounted) {
      setState(() => _sending = false);
      if (!ok)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر إرسال الرسالة')));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _sendImage() async {
    if (_sending) return;
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (file == null) return;
    setState(() => _sending = true);
    final ok = await ref
        .read(chatNotifierProvider.notifier)
        .sendImageMessage(widget.chatId, File(file.path));
    if (mounted) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'تم إرسال الصورة' : 'تعذر إرسال الصورة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final name =
        widget.otherUserName.isEmpty ? 'الإدارة' : widget.otherUserName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        titleSpacing: 4,
        title: Row(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryGradientStart,
              backgroundImage: widget.otherUserAvatar != null
                  ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800))
                  : null),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const Text('محادثة آمنة',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
            child: messagesAsync.when(
          data: (messages) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToBottom());
            if (messages.isEmpty)
              return const Center(
                  child: Text('ابدأ المحادثة الآن',
                      style: TextStyle(color: AppColors.textSecondary)));
            return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                itemCount: messages.length,
                itemBuilder: (_, i) => _MessageBubble(
                    message: messages[i],
                    isMe: messages[i].senderId == currentUserId));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: AppColors.error, size: 42),
                    const SizedBox(height: 12),
                    const Text('تعذر تحميل الرسائل',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ]))),
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                  top: BorderSide(
                      color: AppColors.dividerBorder.withOpacity(.6)))),
          child: SafeArea(
              child: Row(children: [
            IconButton(
                onPressed: _sending ? null : _sendImage,
                icon: const Icon(Icons.image_rounded,
                    color: AppColors.secondaryAccent)),
            Expanded(
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppColors.dividerBorder)),
                    child: TextField(
                        controller: _messageCtrl,
                        style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w500),
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                            hintText: 'اكتب رسالتك...',
                            hintTextDirection: TextDirection.rtl,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12)),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        onSubmitted: (_) => _sendMessage()))),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: _sending ? null : _sendMessage,
                child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: _sending
                            ? AppColors.textSecondary
                            : AppColors.secondaryAccent,
                        shape: BoxShape.circle),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 21))),
          ])),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});
  @override
  Widget build(BuildContext context) {
    final isImage = message.type == MessageType.image;
    return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
          margin: const EdgeInsets.only(bottom: 10),
          padding: isImage
              ? const EdgeInsets.all(4)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: isMe
                  ? AppColors.secondaryAccent
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 18)),
              border: isMe
                  ? null
                  : Border.all(
                      color: AppColors.dividerBorder.withOpacity(.55))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (isImage)
              ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                      imageUrl: message.content,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator())),
                      errorWidget: (_, __, ___) => const SizedBox(
                          width: 220,
                          height: 100,
                          child: Icon(Icons.broken_image_rounded))))
            else
              Text(message.content,
                  style: TextStyle(
                      color: isMe ? Colors.white : null,
                      fontSize: 14,
                      height: 1.45)),
            const SizedBox(height: 3),
            Text(timeago.format(message.createdAt, locale: 'ar'),
                style: TextStyle(
                    color: isMe ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 9)),
          ]),
        ));
  }
}
