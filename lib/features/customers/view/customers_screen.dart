import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/customers_provider.dart';
import '../model/customer.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(customersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'بحث بالاسم أو الجوال...',
                  border: InputBorder.none,
                ),
                onChanged: (q) =>
                    ref.read(customersProvider.notifier).search(q),
              )
            : Text('العملاء (${state.total})'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(customersProvider.notifier).search('');
                }
              });
            },
          ),
        ],
      ),
      body: _buildBody(state, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new customer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('إضافة عميل - قريباً')),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody(CustomersState state, ThemeData theme) {
    if (state.isLoading && state.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(state.error!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(customersProvider.notifier).loadCustomers(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state.filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'لا توجد نتائج لـ "${state.searchQuery}"'
                  : 'لا يوجد عملاء',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(customersProvider.notifier).loadCustomers(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.filtered.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.filtered.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _CustomerTile(
            customer: state.filtered[index],
            onTap: () => _openDetail(state.filtered[index]),
          );
        },
      ),
    );
  }

  void _openDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: customer.name),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: customer.disabled
            ? Colors.grey[300]
            : theme.colorScheme.primaryContainer,
        child: Text(
          customer.initial,
          style: TextStyle(
            color: customer.disabled
                ? Colors.grey[600]
                : theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        customer.customerName,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: customer.disabled ? Colors.grey : null,
        ),
      ),
      subtitle: Row(
        children: [
          if (customer.mobileNo != null && customer.mobileNo!.isNotEmpty) ...[
            Icon(Icons.phone, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              customer.mobileNo!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
          ],
          if (customer.territory != null) ...[
            Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                customer.territory!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: customer.disabled
          ? Chip(
              label: const Text('معطل', style: TextStyle(fontSize: 10)),
              backgroundColor: Colors.grey[200],
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : const Icon(Icons.chevron_left, color: Colors.grey),
      onTap: onTap,
    );
  }
}
