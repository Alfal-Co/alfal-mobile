import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/sales_provider.dart';
import '../model/sales_invoice.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(invoiceDetailProvider(invoiceId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(invoiceId),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('فشل تحميل الفاتورة'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(invoiceDetailProvider(invoiceId)),
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
    final invoice = SalesInvoice.fromJson(data);
    final items = (data['items'] as List? ?? [])
        .map((i) => SalesInvoiceItem.fromJson(i as Map<String, dynamic>))
        .toList();
    final taxes = (data['taxes'] as List? ?? []);
    final totalTax = taxes.fold<double>(
        0, (sum, t) => sum + ((t['tax_amount'] ?? 0) as num).toDouble());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status + Amount header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Status
                _StatusChip(invoice: invoice),
                const SizedBox(height: 16),

                // Grand total
                Text(
                  '${invoice.grandTotal.toStringAsFixed(2)} ر.س',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('الإجمالي',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),

                if (invoice.isOverdue) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'متبقي: ${invoice.outstandingAmount.toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Customer + Date info
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(invoice.customerName),
                subtitle: Text(invoice.customer),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(invoice.postingDate),
                subtitle: const Text('تاريخ الفاتورة'),
              ),
              if (invoice.territory != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(invoice.territory!),
                  subtitle: const Text('المنطقة'),
                ),
              ],
              if (invoice.salesPartner != null &&
                  invoice.salesPartner!.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.handshake),
                  title: Text(invoice.salesPartner!),
                  subtitle: const Text('المندوب'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Items
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text('الأصناف',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${items.length} صنف',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...items.map((item) => _ItemRow(item: item)),
              const Divider(height: 1),

              // Subtotal
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع الفرعي',
                        style: TextStyle(color: Colors.grey[600])),
                    Text(
                      '${(invoice.grandTotal - totalTax).toStringAsFixed(2)} ر.س',
                    ),
                  ],
                ),
              ),

              // Tax
              if (totalTax > 0)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الضريبة (15%)',
                          style: TextStyle(color: Colors.grey[600])),
                      Text('${totalTax.toStringAsFixed(2)} ر.س'),
                    ],
                  ),
                ),

              // Grand total
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '${invoice.grandTotal.toStringAsFixed(2)} ر.س',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SalesInvoice invoice;
  const _StatusChip({required this.invoice});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    if (invoice.isCancelled) {
      bg = Colors.red[50]!;
      fg = Colors.red[700]!;
      icon = Icons.cancel;
    } else if (invoice.isDraft) {
      bg = Colors.orange[50]!;
      fg = Colors.orange[700]!;
      icon = Icons.edit_note;
    } else if (invoice.isPaid) {
      bg = Colors.green[50]!;
      fg = Colors.green[700]!;
      icon = Icons.check_circle;
    } else {
      bg = Colors.blue[50]!;
      fg = Colors.blue[700]!;
      icon = Icons.pending;
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
          Text(
            invoice.statusLabel,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final SalesInvoiceItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.qty.toStringAsFixed(0)} × ${item.rate.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${item.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
