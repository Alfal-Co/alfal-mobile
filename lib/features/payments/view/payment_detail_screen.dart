import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/payments_provider.dart';
import '../model/payment_entry.dart';

class PaymentDetailScreen extends ConsumerWidget {
  final String paymentId;

  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(paymentDetailProvider(paymentId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(paymentId)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('فشل تحميل بيانات الدفعة'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(paymentDetailProvider(paymentId)),
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
    final payment = PaymentEntry.fromJson(data);
    final references = (data['references'] as List? ?? []);
    final remarks = data['remarks'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Amount card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status
                _StatusChip(payment: payment),
                const SizedBox(height: 16),

                // Amount
                Text(
                  '${payment.paidAmount.toStringAsFixed(2)} ر.س',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: payment.isCancelled
                        ? Colors.grey
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(payment.modeIcon, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      payment.modeLabel,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Party & date info
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(payment.partyName),
                subtitle: Text(payment.party),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(payment.postingDate),
                subtitle: const Text('تاريخ الدفعة'),
              ),
              if (payment.referenceNo != null &&
                  payment.referenceNo!.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tag),
                  title: Text(payment.referenceNo!),
                  subtitle: Text(payment.referenceDate != null
                      ? 'رقم المرجع - ${payment.referenceDate}'
                      : 'رقم المرجع'),
                ),
              ],
              if (payment.paidTo != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: Text(payment.paidTo!),
                  subtitle: const Text('إلى حساب'),
                ),
              ],
            ],
          ),
        ),

        // Linked invoices
        if (references.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('الفواتير المرتبطة',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ...references.map((ref) {
                  final refName =
                      ref['reference_name'] as String? ?? '';
                  final refType =
                      ref['reference_doctype'] as String? ?? '';
                  final allocated =
                      (ref['allocated_amount'] ?? 0).toDouble();
                  final total =
                      (ref['total_amount'] ?? 0).toDouble();

                  return ListTile(
                    leading: const Icon(Icons.receipt, size: 20),
                    title: Text(refName),
                    subtitle: Text(
                      refType == 'Sales Invoice'
                          ? 'فاتورة مبيعات'
                          : refType,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${allocated.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (total > 0)
                          Text(
                            'من ${total.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // Remarks
        if (remarks != null && remarks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ملاحظات',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(remarks,
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PaymentEntry payment;
  const _StatusChip({required this.payment});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    if (payment.isCancelled) {
      bg = Colors.red[50]!;
      fg = Colors.red[700]!;
      icon = Icons.cancel;
    } else if (payment.isDraft) {
      bg = Colors.orange[50]!;
      fg = Colors.orange[700]!;
      icon = Icons.edit_note;
    } else {
      bg = Colors.green[50]!;
      fg = Colors.green[700]!;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(payment.statusLabel,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
