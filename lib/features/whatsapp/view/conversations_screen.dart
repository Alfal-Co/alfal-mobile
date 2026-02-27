import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/whatsapp_service.dart';
import '../provider/whatsapp_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('محادثات واتساب')),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('خطأ في تحميل المحادثات',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(conversationsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('لا توجد محادثات',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                return _ConversationTile(
                  message: conversations[index],
                  onTap: () => _openChat(context, conversations[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, WaMessage msg) {
    final phone = msg.isIncoming ? msg.from : msg.to;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(phone: phone),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final WaMessage message;
  final VoidCallback onTap;

  const _ConversationTile({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final phone = message.isIncoming ? message.from : message.to;
    final timeStr = _formatTime(message.creation);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: Icon(Icons.person, color: Colors.green[700]),
      ),
      title: Text(
        phone,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        message.message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Text(
        timeStr,
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes} د';
    if (diff.inHours < 24) return '${diff.inHours} س';
    if (diff.inDays < 7) return '${diff.inDays} ي';
    return '${dt.day}/${dt.month}';
  }
}
