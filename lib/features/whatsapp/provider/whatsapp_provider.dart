import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/whatsapp_service.dart';
import '../../../core/auth/auth_provider.dart';

/// Evolution WhatsApp service singleton
final whatsappServiceProvider = Provider<WhatsAppService>((ref) {
  return EvolutionWhatsAppService();
});

/// Check connection state for a session
final connectionStateProvider =
    FutureProvider.family<String, String>((ref, session) async {
  final service = ref.read(whatsappServiceProvider);
  return service.checkConnection(session);
});

/// Fetch WhatsApp messages from ERPNext (WhatsApp Message DocType)
final whatsappMessagesProvider =
    FutureProvider.family<List<WaMessage>, String>((ref, phone) async {
  final client = ref.read(erpnextClientProvider);
  final results = await client.getList(
    'WhatsApp Message',
    fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
    filters: [
      ['to', 'like', '%$phone%'],
    ],
    orderBy: 'creation desc',
    limitPageLength: 50,
  );
  return results
      .map((json) => WaMessage.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Fetch all conversations grouped by phone number (latest message per contact)
final conversationsProvider =
    FutureProvider<List<WaMessage>>((ref) async {
  final client = ref.read(erpnextClientProvider);
  final results = await client.getList(
    'WhatsApp Message',
    fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
    orderBy: 'creation desc',
    limitPageLength: 200,
  );

  final messages = results
      .map((json) => WaMessage.fromJson(json as Map<String, dynamic>))
      .toList();

  // Group by phone: keep only latest message per contact
  final Map<String, WaMessage> latestByPhone = {};
  for (final msg in messages) {
    final phone = msg.isIncoming ? msg.from : msg.to;
    if (phone.isNotEmpty && !latestByPhone.containsKey(phone)) {
      latestByPhone[phone] = msg;
    }
  }

  return latestByPhone.values.toList();
});
