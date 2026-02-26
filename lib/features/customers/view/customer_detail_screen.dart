import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/customers_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(customerDetailProvider(customerId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العميل'),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              const Text('فشل تحميل بيانات العميل'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(customerDetailProvider(customerId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (data) => _buildDetail(context, data, theme),
      ),
    );
  }

  Widget _buildDetail(
      BuildContext context, Map<String, dynamic> data, ThemeData theme) {
    final name = data['customer_name'] as String? ?? customerId;
    final balance = (data['outstanding_balance'] ?? 0).toDouble();
    final mobile = data['mobile_no'] as String?;
    final email = data['email_id'] as String?;
    final group = data['customer_group'] as String?;
    final territory = data['territory'] as String?;
    final type = data['customer_type'] as String?;
    final taxId = data['tax_id'] as String?;
    final address = data['customer_primary_address'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card with name and balance
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  customerId,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Balance
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: balance > 0
                        ? Colors.red[50]
                        : balance < 0
                            ? Colors.green[50]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'الرصيد المستحق',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${balance.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: balance > 0
                              ? Colors.red[700]
                              : balance < 0
                                  ? Colors.green[700]
                                  : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Quick actions
        if (mobile != null && mobile.isNotEmpty)
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.phone, color: Colors.green),
                  title: Text(mobile),
                  subtitle: const Text('جوال'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone),
                        color: Colors.green,
                        onPressed: () => _makeCall(mobile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.message),
                        color: Colors.green,
                        onPressed: () => _openWhatsApp(mobile),
                      ),
                    ],
                  ),
                ),
                if (email != null && email.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.blue),
                    title: Text(email),
                    subtitle: const Text('البريد'),
                    onTap: () => _sendEmail(email),
                  ),
              ],
            ),
          )
        else if (email != null && email.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(email),
              subtitle: const Text('البريد'),
              onTap: () => _sendEmail(email),
            ),
          ),
        const SizedBox(height: 12),

        // Info card
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('معلومات العميل',
                    style: theme.textTheme.titleSmall),
              ),
              if (type != null)
                _InfoRow(label: 'النوع', value: type),
              if (group != null)
                _InfoRow(label: 'المجموعة', value: group),
              if (territory != null)
                _InfoRow(label: 'المنطقة', value: territory),
              if (taxId != null && taxId.isNotEmpty)
                _InfoRow(label: 'الرقم الضريبي', value: taxId),
              if (address != null && address.isNotEmpty)
                _InfoRow(label: 'العنوان', value: address),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  void _makeCall(String number) {
    launchUrl(Uri.parse('tel:$number'));
  }

  void _openWhatsApp(String number) {
    // Remove spaces and leading zeros, add country code if needed
    var clean = number.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.startsWith('05')) {
      clean = '966${clean.substring(1)}';
    } else if (!clean.startsWith('+') && !clean.startsWith('966')) {
      clean = '966$clean';
    }
    launchUrl(Uri.parse('https://wa.me/$clean'));
  }

  void _sendEmail(String email) {
    launchUrl(Uri.parse('mailto:$email'));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
