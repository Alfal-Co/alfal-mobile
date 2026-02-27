import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../model/employee.dart';

/// Provider that fetches the current logged-in user's Employee record.
/// Logic: auth.username (user_id) → search Employee where user_id = username → getDoc for full fields
final myEmployeeProvider = FutureProvider<Employee?>((ref) async {
  final auth = ref.watch(authProvider);
  final client = ref.read(erpnextClientProvider);

  if (!auth.isAuthenticated || auth.username == null) return null;

  // Step 1: Find Employee linked to this user
  final results = await client.getList(
    'Employee',
    fields: ['name'],
    filters: [
      ['user_id', '=', auth.username],
      ['status', '=', 'Active'],
    ],
    limitPageLength: 1,
  );

  if (results.isEmpty) return null;

  final employeeId = results[0]['name'] as String;

  // Step 2: getDoc for full fields (including cell_phone, personal_phone)
  final doc = await client.getDoc('Employee', employeeId);
  return Employee.fromJson(doc);
});
