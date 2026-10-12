import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/nova_ai_service.dart';

class NovaAssistantFab extends StatelessWidget {
  const NovaAssistantFab({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        heroTag: 'nova-assistant-fab',
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _NovaSheet(),
        ),
        backgroundColor: AppColors.primaryGradientStart,
        foregroundColor: Colors.white,
        elevation: 14,
        icon: const Icon(Icons.auto_awesome_rounded),
        label:
            const Text('Nova', style: TextStyle(fontWeight: FontWeight.w900)),
      );
}

class _NovaSheet extends StatefulWidget {
  const _NovaSheet();
  @override
  State<_NovaSheet> createState() => _NovaSheetState();
}

class _NovaSheetState extends State<_NovaSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _ai = NovaAiService();
  bool _isThinking = false;
  final List<_NovaMessage> _messages = [
    const _NovaMessage(
      text:
          'أهلاً بيك في Nova 🤖\nأنا المساعد الذكي لـ 𝐇𝐚𝐦𝐨.\n\nاسألني عن العروض، التحويل، التفعيل أو الاسترداد، وهفهم سؤالك وأساعدك خطوة بخطوة.',
      fromUser: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask([String? question]) async {
    if (_isThinking) return;
    final text = (question ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    final history = _messages
        .map((m) => {'role': m.fromUser ? 'user' : 'model', 'text': m.text})
        .toList();
    setState(() {
      _messages.add(_NovaMessage(text: text, fromUser: true));
      _isThinking = true;
    });
    _scrollToEnd();

    try {
      final answer = await _ai.ask(message: text, history: history);
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(_NovaMessage(
          text: answer,
          fromUser: false,
          copyCashNumbers: _isCashQuestion(text),
        ));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(_NovaMessage(
          text:
              'مش قادر أوصل لـ Nova دلوقتي. جرّب تاني بعد لحظات، ولو سؤالك عن الكاش فالأرقام المعتمدة موجودة تحت.',
          fromUser: false,
          copyCashNumbers: _isCashQuestion(text),
        ));
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isCashQuestion(String question) {
    final q = question.toLowerCase();
    return q.contains('كاش') || q.contains('تحويل') || q.contains('رقم');
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      height: MediaQuery.sizeOf(context).height * .86,
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryGradientStart.withOpacity(.35),
              blurRadius: 34,
              offset: const Offset(0, -10))
        ],
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
                color: AppColors.dividerBorder,
                borderRadius: BorderRadius.circular(5))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: AppColors.primaryButtonShadow),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 27),
            ),
            const SizedBox(width: 11),
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Nova AI',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text('مساعد 𝐇𝐚𝐦𝐨 الذكي',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                Icon(Icons.circle, color: AppColors.success, size: 8),
                SizedBox(width: 5),
                Text('متصل',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700))
              ]),
            ),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded)),
          ]),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _QuickQuestion(
                  label: 'طريقة الاستخدام',
                  onTap: () => _ask('إزاي التطبيق شغال؟')),
              _QuickQuestion(
                  label: 'أرقام الكاش', onTap: () => _ask('عايز أرقام الكاش')),
              _QuickQuestion(
                  label: 'التفعيل', onTap: () => _ask('حولت ومفيش تفعيل')),
              _QuickQuestion(
                  label: 'الاسترداد',
                  onTap: () => _ask('هل يمكن استرداد الأموال؟')),
              _QuickQuestion(
                  label: 'الأدمن', onTap: () => _ask('عايز أكلم الأدمن')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            itemCount: _messages.length + (_isThinking ? 1 : 0),
            itemBuilder: (_, index) {
              if (_isThinking && index == _messages.length)
                return const _ThinkingBubble();
              final message = _messages[index];
              return _MessageBubble(message: message);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isThinking,
                textDirection: TextDirection.rtl,
                onSubmitted: (_) => _ask(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: _isThinking ? 'Nova بتفكر...' : 'اكتب سؤالك...',
                  hintTextDirection: TextDirection.rtl,
                  filled: true,
                  suffixIcon: IconButton(
                      onPressed: _isThinking ? null : () => _ask(),
                      icon: const Icon(Icons.send_rounded,
                          color: AppColors.secondaryAccent)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _NovaMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) => Align(
        alignment:
            message.fromUser ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .84),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: message.fromUser
                ? const LinearGradient(colors: [
                    AppColors.primaryGradientStart,
                    AppColors.primaryGradientEnd
                  ])
                : null,
            color:
                message.fromUser ? null : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(19),
            border: message.fromUser
                ? null
                : Border.all(color: AppColors.dividerBorder.withOpacity(.6)),
            boxShadow: message.fromUser ? AppColors.softShadow : null,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(message.text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    color: message.fromUser ? Colors.white : null,
                    height: 1.55,
                    fontSize: 14)),
            if (message.copyCashNumbers) ...[
              const SizedBox(height: 10),
              ...AppConstants.cashNumbers
                  .map((number) => _NovaCashRow(number: number)),
            ],
          ]),
        ),
      );
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();
  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: FadeTransition(
          opacity: Tween(begin: .55, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                    color: AppColors.secondaryAccent.withOpacity(.55)),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.secondaryAccent.withOpacity(.18),
                      blurRadius: 15)
                ]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.secondaryAccent, size: 18),
              const SizedBox(width: 8),
              const Text('جارٍ التفكير...',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryAccent)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.secondaryAccent)),
            ]),
          ),
        ),
      );
}

class _QuickQuestion extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickQuestion({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ActionChip(
          label: Text(label),
          onPressed: onTap,
          avatar: const Icon(Icons.bolt_rounded,
              size: 16, color: AppColors.secondaryAccent)));
}

class _NovaMessage {
  final String text;
  final bool fromUser;
  final bool copyCashNumbers;
  const _NovaMessage(
      {required this.text,
      required this.fromUser,
      this.copyCashNumbers = false});
}

class _NovaCashRow extends StatelessWidget {
  final String number;
  const _NovaCashRow({required this.number});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
            color: AppColors.primaryGradientStart.withOpacity(.10),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.phone_android_rounded,
              color: AppColors.secondaryAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(number,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1))),
          IconButton(
              tooltip: 'نسخ الرقم',
              icon: const Icon(Icons.copy_rounded,
                  color: AppColors.secondaryAccent, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: number));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ رقم الكاش')));
              }),
        ]),
      );
}

class AdminCashCard extends StatelessWidget {
  const AdminCashCard({super.key});
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.notificationYellow),
              const SizedBox(width: 8),
              Text('أرقام كاش الإدارة',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900))
            ]),
            const SizedBox(height: 6),
            const Text('تأكد من الرقم قبل إجراء أي تحويل.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            ...AppConstants.cashNumbers.map((number) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_android_rounded,
                    color: AppColors.secondaryAccent),
                title: Text(number,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1)),
                trailing: IconButton(
                    tooltip: 'نسخ الرقم',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: number));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ رقم الكاش')));
                    }))),
          ]),
        ),
      );
}
