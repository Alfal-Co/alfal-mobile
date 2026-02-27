import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/ai_provider.dart';
import '../model/chat_message.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize AI channel when screen opens (auth is ready by now)
    Future.microtask(() {
      ref.read(aiProvider.notifier).ensureInitialized();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(aiProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider);
    final theme = Theme.of(context);

    if (state.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الذكي'),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'مسح المحادثة',
              onPressed: () => ref.read(aiProvider.notifier).clearChat(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (state.error != null)
            MaterialBanner(
              content: Text(state.error!),
              leading: const Icon(Icons.error_outline, color: Colors.red),
              actions: [
                TextButton(
                  onPressed: () =>
                      ref.read(aiProvider.notifier).retryInit(),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),

          // Chat messages
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyState(
                    onSuggestionTap: _sendMessage,
                    hasError: state.error != null,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: state.messages.length +
                        (state.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length &&
                          state.isTyping) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(
                        message: state.messages[index],
                        theme: theme,
                      );
                    },
                  ),
          ),

          // Quick suggestions (only when few messages)
          if (state.messages.length < 4 && state.error == null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  _QuickChip(
                    label: 'مبيعات اليوم',
                    onTap: () => _sendMessage('كم مبيعات اليوم؟'),
                  ),
                  _QuickChip(
                    label: 'تحصيلات اليوم',
                    onTap: () => _sendMessage('كم تحصيلات اليوم؟'),
                  ),
                  _QuickChip(
                    label: 'فواتير متأخرة',
                    onTap: () =>
                        _sendMessage('أعطني الفواتير غير المدفوعة'),
                  ),
                  _QuickChip(
                    label: 'إحصائيات',
                    onTap: () => _sendMessage('أعطني إحصائيات عامة'),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textDirection: TextDirection.rtl,
                      enabled: state.error == null,
                      decoration: InputDecoration(
                        hintText: state.error != null
                            ? 'المساعد غير متصل...'
                            : 'اكتب سؤالك هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isTyping || state.error != null
                        ? null
                        : () => _sendMessage(_controller.text),
                    icon: state.isTyping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state with welcome message
class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;
  final bool hasError;

  const _EmptyState({
    required this.onSuggestionTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: hasError
                    ? Colors.red[50]
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                hasError ? Icons.smart_toy_outlined : Icons.smart_toy,
                size: 40,
                color: hasError
                    ? Colors.red[300]
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasError ? 'المساعد غير متصل' : 'مرحباً! أنا مساعد الفال',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasError
                  ? 'تأكد من تسجيلك في Raven وأعد المحاولة'
                  : 'اسألني عن العملاء، المبيعات، التحصيلات،\nأو أي شي يخص النظام',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (!hasError) ...[
              const SizedBox(height: 32),
              Text(
                'جرّب تسأل:',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _SuggestionCard(
                    icon: Icons.trending_up,
                    label: 'كم مبيعات اليوم؟',
                    onTap: () => onSuggestionTap('كم مبيعات اليوم؟'),
                  ),
                  _SuggestionCard(
                    icon: Icons.account_balance_wallet,
                    label: 'كم تحصيلات اليوم؟',
                    onTap: () => onSuggestionTap('كم تحصيلات اليوم؟'),
                  ),
                  _SuggestionCard(
                    icon: Icons.receipt_long,
                    label: 'الفواتير المتأخرة',
                    onTap: () =>
                        onSuggestionTap('أعطني الفواتير غير المدفوعة'),
                  ),
                  _SuggestionCard(
                    icon: Icons.bar_chart,
                    label: 'إحصائيات عامة',
                    onTap: () => onSuggestionTap('أعطني إحصائيات عامة'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Chat message bubble
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ThemeData theme;

  const _MessageBubble({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white60 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Typing indicator (three dots animation)
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final t = ((_animController.value - delay) % 1.0)
                        .clamp(0.0, 1.0);
                    final y = -4.0 * (t < 0.5 ? t : 1.0 - t);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                              alpha:
                                  0.5 + 0.5 * (t < 0.5 ? t : 1.0 - t)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick suggestion chip
class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
      ),
    );
  }
}
