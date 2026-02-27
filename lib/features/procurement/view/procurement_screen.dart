import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/procurement_provider.dart';
import '../model/material_request.dart';
import 'widgets/workflow_state_badge.dart';
import 'create_request_screen.dart';
import 'request_detail_screen.dart';

class ProcurementScreen extends ConsumerStatefulWidget {
  const ProcurementScreen({super.key});

  @override
  ConsumerState<ProcurementScreen> createState() => _ProcurementScreenState();
}

class _ProcurementScreenState extends ConsumerState<ProcurementScreen> {
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
      ref.read(procurementProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(procurementProvider);

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
                    ref.read(procurementProvider.notifier).search(q),
              )
            : Text('المشتريات (${state.total})'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(procurementProvider.notifier).search('');
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createRequest(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _FilterBar(
            current: state.filter,
            onChanged: (f) =>
                ref.read(procurementProvider.notifier).setFilter(f),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ProcurementListState state) {
    if (state.isLoading && state.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.requests.isEmpty) {
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
                  .read(procurementProvider.notifier)
                  .loadRequests(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات شراء',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(procurementProvider.notifier).loadRequests(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.requests.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.requests.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _RequestTile(
            request: state.requests[index],
            onTap: () => _openDetail(state.requests[index]),
          );
        },
      ),
    );
  }

  void _openDetail(MaterialRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(requestId: request.name),
      ),
    );
  }

  void _createRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateRequestScreen(),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ProcurementFilter current;
  final ValueChanged<ProcurementFilter> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip('الكل', ProcurementFilter.all),
          _chip('بانتظار إجراءي', ProcurementFilter.pendingMyAction),
          _chip('مسودة', ProcurementFilter.draft),
          _chip('المشرف', ProcurementFilter.pendingSupervisor),
          _chip('المشتريات', ProcurementFilter.pendingPurchase),
          _chip('المالية', ProcurementFilter.pendingFinance),
          _chip('تم الاستلام', ProcurementFilter.received),
        ],
      ),
    );
  }

  Widget _chip(String label, ProcurementFilter filter) {
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

class _RequestTile extends StatelessWidget {
  final MaterialRequest request;
  final VoidCallback onTap;

  const _RequestTile({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              // Top row: request name + state badge
              Row(
                children: [
                  Text(
                    request.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  WorkflowStateBadge(procurementState: request.state),
                ],
              ),
              const SizedBox(height: 8),

              // Customer name
              if (request.customer != null && request.customer!.isNotEmpty)
                Text(
                  request.customer!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              // Creator info
              if (request.ownerName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      request.ownerName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),

              // Bottom row: date + qty + WhatsApp indicator
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    request.transactionDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  if (request.totalQty != null && request.totalQty! > 0) ...[
                    Icon(Icons.inventory_2,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${request.totalQty!.toStringAsFixed(0)} صنف',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  const Spacer(),
                  if (request.hasWhatsappSource)
                    Icon(Icons.chat,
                        size: 16, color: Colors.green[600]),
                  if (request.isRejected)
                    Icon(Icons.cancel,
                        size: 16, color: Colors.red[600]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
