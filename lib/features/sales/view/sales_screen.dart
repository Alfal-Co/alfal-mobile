import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/sales_provider.dart';
import '../model/sales_invoice.dart';
import 'invoice_detail_screen.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(salesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'بحث باسم العميل...',
                  border: InputBorder.none,
                ),
                onSubmitted: (q) => ref.read(salesProvider.notifier).search(q),
              )
            : Text('المبيعات (${state.total})'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(salesProvider.notifier).search('');
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _FilterBar(
            current: state.filter,
            onChanged: (f) => ref.read(salesProvider.notifier).setFilter(f),
          ),
          // Invoice list
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(SalesState state) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(salesProvider.notifier).loadInvoices(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state.invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'لا توجد فواتير',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(salesProvider.notifier).loadInvoices(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.invoices.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _InvoiceTile(
            invoice: state.invoices[index],
            onTap: () => _openDetail(state.invoices[index]),
          );
        },
      ),
    );
  }

  void _openDetail(SalesInvoice invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoiceId: invoice.name),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final InvoiceFilter current;
  final ValueChanged<InvoiceFilter> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip('الكل', InvoiceFilter.all),
          _chip('غير مدفوعة', InvoiceFilter.unpaid),
          _chip('مدفوعة', InvoiceFilter.paid),
          _chip('مسودة', InvoiceFilter.draft),
          _chip('ملغية', InvoiceFilter.cancelled),
        ],
      ),
    );
  }

  Widget _chip(String label, InvoiceFilter filter) {
    final selected = current == filter;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onChanged(filter),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final SalesInvoice invoice;
  final VoidCallback onTap;

  const _InvoiceTile({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: invoice name + status
              Row(
                children: [
                  Text(
                    invoice.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(invoice: invoice),
                ],
              ),
              const SizedBox(height: 8),

              // Customer name
              Text(
                invoice.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Bottom row: date + amount
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    invoice.postingDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '${invoice.grandTotal.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              // Outstanding amount if any
              if (invoice.isOverdue) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'متبقي: ${invoice.outstandingAmount.toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SalesInvoice invoice;

  const _StatusBadge({required this.invoice});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (invoice.isCancelled) {
      bg = Colors.red[50]!;
      fg = Colors.red[700]!;
    } else if (invoice.isDraft) {
      bg = Colors.orange[50]!;
      fg = Colors.orange[700]!;
    } else if (invoice.isPaid) {
      bg = Colors.green[50]!;
      fg = Colors.green[700]!;
    } else {
      bg = Colors.blue[50]!;
      fg = Colors.blue[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        invoice.statusLabel,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
