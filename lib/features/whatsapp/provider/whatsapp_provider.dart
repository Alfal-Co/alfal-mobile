import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/whatsapp_service.dart';
import '../../../core/auth/auth_provider.dart';
import '../../hr/provider/employee_provider.dart';

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

/// Fetch WhatsApp messages for a specific phone conversation
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

/// Fetch conversations filtered by the current employee's department phone.
/// Each employee only sees conversations from their department's WhatsApp number.
final conversationsProvider =
    FutureProvider<List<WaMessage>>((ref) async {
  final client = ref.read(erpnextClientProvider);
  final employee = await ref.watch(myEmployeeProvider.future);

  // Get department phone for filtering
  final deptPhone = employee?.sessionPhone;

  List<dynamic> results;
  if (deptPhone != null) {
    // Filter: messages where from OR to matches department phone
    results = await client.getList(
      'WhatsApp Message',
      fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
      filters: [
        ['from', 'like', '%$deptPhone%'],
      ],
      orderBy: 'creation desc',
      limitPageLength: 200,
    );

    // Also fetch outgoing messages from this department number
    final outgoing = await client.getList(
      'WhatsApp Message',
      fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
      filters: [
        ['to', 'like', '%$deptPhone%'],
      ],
      orderBy: 'creation desc',
      limitPageLength: 200,
    );

    // Merge and deduplicate by name
    final allNames = results.map((r) => (r as Map)['name']).toSet();
    for (final msg in outgoing) {
      if (!allNames.contains((msg as Map)['name'])) {
        results.add(msg);
      }
    }
  } else {
    // No employee record: fetch all (admin/fallback)
    results = await client.getList(
      'WhatsApp Message',
      fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
      orderBy: 'creation desc',
      limitPageLength: 200,
    );
  }

  final messages = results
      .map((json) => WaMessage.fromJson(json as Map<String, dynamic>))
      .toList();

  // Sort by creation descending (after merge)
  messages.sort((a, b) => b.creation.compareTo(a.creation));

  // Group by phone: keep only latest message per contact
  final Map<String, WaMessage> latestByPhone = {};
  for (final msg in messages) {
    // The "other party" phone (not our department number)
    final phone = msg.isIncoming ? msg.from : msg.to;
    if (phone.isNotEmpty && !latestByPhone.containsKey(phone)) {
      latestByPhone[phone] = msg;
    }
  }

  return latestByPhone.values.toList();
});
