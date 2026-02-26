import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/payments_provider.dart';
import '../model/payment_entry.dart';
import 'payment_detail_screen.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
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
      ref.read(paymentsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);
    final theme = Theme.of(context);

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
                onSubmitted: (q) =>
                    ref.read(paymentsProvider.notifier).search(q),
              )
            : Text('التحصيل (${state.total})'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(paymentsProvider.notifier).search('');
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's total
          if (!state.isLoading || state.payments.isNotEmpty)
            _TodaySummary(total: state.todayTotal),

          // Filters
          _FilterBar(
            current: state.filter,
            onChanged: (f) =>
                ref.read(paymentsProvider.notifier).setFilter(f),
          ),

          // List
          Expanded(child: _buildBody(state, theme)),
        ],
      ),
    );
  }

  Widget _buildBody(PaymentsState state, ThemeData theme) {
    if (state.isLoading && state.payments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref
                  .read(paymentsProvider.notifier)
                  .loadPayments(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('لا توجد تحصيلات',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(paymentsProvider.notifier).loadPayments(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.payments.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.payments.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _PaymentTile(
            payment: state.payments[index],
            onTap: () => _openDetail(state.payments[index]),
          );
        },
      ),
    );
  }

  void _openDetail(PaymentEntry payment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentDetailScreen(paymentId: payment.name),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final double total;
  const _TodaySummary({required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.today, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تحصيلات اليوم',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                '${total.toStringAsFixed(2)} ر.س',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final PaymentFilter current;
  final ValueChanged<PaymentFilter> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip('الكل', PaymentFilter.all),
          _chip('مقبوضة', PaymentFilter.submitted),
          _chip('مسودة', PaymentFilter.draft),
          _chip('ملغية', PaymentFilter.cancelled),
        ],
      ),
    );
  }

  Widget _chip(String label, PaymentFilter filter) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: current == filter,
        onSelected: (_) => onChanged(filter),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentEntry payment;
  final VoidCallback onTap;

  const _PaymentTile({required this.payment, required this.onTap});

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
          child: Row(
            children: [
              // Mode icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: payment.isCancelled
                      ? Colors.grey[100]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  payment.modeIcon,
                  color: payment.isCancelled
                      ? Colors.grey
                      : Colors.green[700],
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.partyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          payment.modeLabel,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          payment.postingDate,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${payment.paidAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: payment.isCancelled
                          ? Colors.grey
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusDot(payment: payment),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final PaymentEntry payment;
  const _StatusDot({required this.payment});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (payment.isCancelled) {
      color = Colors.red;
    } else if (payment.isDraft) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          payment.statusLabel,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
