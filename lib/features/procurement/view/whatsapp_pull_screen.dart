import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';

/// Provider to load recent WhatsApp messages
final recentWhatsAppMessagesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(erpnextClientProvider);

  // Get messages from the last 48 hours
  final since = DateTime.now()
      .subtract(const Duration(hours: 48))
      .toIso8601String()
      .split('T')
      .first;

  final messages = await client.getList(
    'WhatsApp Message',
    fields: [
      'name',
      'from',
      'to',
      'message',
      'message_type',
      'creation',
      'contact_name',
      'type',
    ],
    filters: [
      ['creation', '>=', since],
      ['type', '=', 'Incoming'],
      ['message_type', '=', 'text'],
    ],
    orderBy: 'creation desc',
    limitPageLength: 50,
  );

  return messages.cast<Map<String, dynamic>>();
});

class WhatsAppPullScreen extends ConsumerWidget {
  final void Function(
    String messageId,
    String? customer,
    List<Map<String, dynamic>>? items,
  ) onSelect;

  const WhatsAppPullScreen({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(recentWhatsAppMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سحب من واتساب'),
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('فشل تحميل الرسائل'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(recentWhatsAppMessagesProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد رسائل واردة (آخر 48 ساعة)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return _MessageTile(
                message: msg,
                onPull: () => _pullMessage(context, msg),
              );
            },
          );
        },
      ),
    );
  }

  void _pullMessage(BuildContext context, Map<String, dynamic> msg) {
    final contactName = msg['contact_name'] as String? ?? '';
    final messageId = msg['name'] as String;

    // Basic extraction: pass the raw message text as a single item
    // In the future, AI will parse this into structured items
    onSelect(
      messageId,
      contactName.isNotEmpty ? contactName : null,
      null, // Items will be manually entered for now
    );
  }
}

class _MessageTile extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onPull;

  const _MessageTile({required this.message, required this.onPull});

  @override
  Widget build(BuildContext context) {
    final contactName =
        message['contact_name'] as String? ?? message['from'] as String? ?? '';
    final messageText = message['message'] as String? ?? '';
    final creation = message['creation'] as String? ?? '';
    final timeAgo = _formatTimeAgo(creation);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: contact + time
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green[50],
                  child: Icon(Icons.person, size: 18, color: Colors.green[700]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contactName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Message body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                messageText,
                style: const TextStyle(fontSize: 13, height: 1.5),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // Pull button
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: onPull,
                child: const Text('سحب هذا الطلب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String creation) {
    if (creation.isEmpty) return '';
    try {
      final dt = DateTime.parse(creation);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
      return 'قبل ${diff.inDays} يوم';
    } catch (_) {
      return creation.split(' ').first;
    }
  }
}
