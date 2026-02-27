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

/// Fetch conversations for a specific employee phone number
/// Groups messages by contact, showing latest message per contact
final conversationsProvider =
    FutureProvider.family<List<WaMessage>, String>((ref, employeePhone) async {
  final client = ref.read(erpnextClientProvider);

  // Fetch messages where employee phone appears as sender OR receiver
  final results = await client.getList(
    'WhatsApp Message',
    fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
    filters: [
      ['to', 'like', '%$employeePhone%'],
    ],
    orderBy: 'creation desc',
    limitPageLength: 200,
  );

  // Also fetch incoming messages (from contains the employee phone)
  final incomingResults = await client.getList(
    'WhatsApp Message',
    fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
    filters: [
      ['from', 'like', '%$employeePhone%'],
    ],
    orderBy: 'creation desc',
    limitPageLength: 200,
  );

  // Merge and deduplicate by message name
  final Map<String, WaMessage> allMessages = {};
  for (final json in results) {
    final msg = WaMessage.fromJson(json as Map<String, dynamic>);
    allMessages[msg.name] = msg;
  }
  for (final json in incomingResults) {
    final msg = WaMessage.fromJson(json as Map<String, dynamic>);
    allMessages[msg.name] = msg;
  }

  // Sort by creation desc
  final sorted = allMessages.values.toList()
    ..sort((a, b) => b.creation.compareTo(a.creation));

  // Group by contact phone: keep only latest message per contact
  final Map<String, WaMessage> latestByPhone = {};
  for (final msg in sorted) {
    // The "other" party is whoever is NOT the employee
    final otherPhone = msg.isIncoming ? msg.from : msg.to;
    if (otherPhone.isNotEmpty && !latestByPhone.containsKey(otherPhone)) {
      latestByPhone[otherPhone] = msg;
    }
  }

  return latestByPhone.values.toList();
});
