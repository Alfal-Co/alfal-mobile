import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../model/customer.dart';

class CustomersState {
  final bool isLoading;
  final String? error;
  final List<Customer> customers;
  final List<Customer> filtered;
  final String searchQuery;
  final int total;
  final bool hasMore;

  const CustomersState({
    this.isLoading = false,
    this.error,
    this.customers = const [],
    this.filtered = const [],
    this.searchQuery = '',
    this.total = 0,
    this.hasMore = true,
  });

  CustomersState copyWith({
    bool? isLoading,
    String? error,
    List<Customer>? customers,
    List<Customer>? filtered,
    String? searchQuery,
    int? total,
    bool? hasMore,
  }) {
    return CustomersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      customers: customers ?? this.customers,
      filtered: filtered ?? this.filtered,
      searchQuery: searchQuery ?? this.searchQuery,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  final Ref _ref;
  static const _pageSize = 50;

  CustomersNotifier(this._ref) : super(const CustomersState()) {
    loadCustomers();
  }

  Future<void> loadCustomers({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    final client = _ref.read(erpnextClientProvider);

    try {
      final results = await Future.wait([
        client.getList(
          'Customer',
          fields: [
            'name',
            'customer_name',
            'customer_group',
            'territory',
            'mobile_no',
            'email_id',
            'customer_type',
            'disabled',
          ],
          orderBy: 'customer_name asc',
          limitPageLength: _pageSize,
          limitStart: 0,
        ),
        client.getCount('Customer'),
      ]);

      final list = (results[0] as List)
          .map((j) => Customer.fromJson(j as Map<String, dynamic>))
          .toList();
      final total = results[1] as int;

      state = state.copyWith(
        isLoading: false,
        customers: list,
        filtered: list,
        total: total,
        hasMore: list.length < total,
        searchQuery: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل العملاء',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final client = _ref.read(erpnextClientProvider);

    try {
      final list = await client.getList(
        'Customer',
        fields: [
          'name',
          'customer_name',
          'customer_group',
          'territory',
          'mobile_no',
          'email_id',
          'customer_type',
          'disabled',
        ],
        orderBy: 'customer_name asc',
        limitPageLength: _pageSize,
        limitStart: state.customers.length,
      );

      final newCustomers = list
          .map((j) => Customer.fromJson(j as Map<String, dynamic>))
          .toList();
      final all = [...state.customers, ...newCustomers];

      state = state.copyWith(
        isLoading: false,
        customers: all,
        filtered: state.searchQuery.isEmpty ? all : _applySearch(all, state.searchQuery),
        hasMore: all.length < state.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void search(String query) {
    final q = query.trim();
    state = state.copyWith(
      searchQuery: q,
      filtered: q.isEmpty ? state.customers : _applySearch(state.customers, q),
    );
  }

  List<Customer> _applySearch(List<Customer> list, String query) {
    final q = query.toLowerCase();
    return list.where((c) {
      return c.customerName.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          (c.mobileNo?.contains(q) ?? false) ||
          (c.territory?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}

final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  return CustomersNotifier(ref);
});

/// Provider for a single customer's detail with balance
final customerDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, customerId) async {
  final client = ref.read(erpnextClientProvider);

  final results = await Future.wait([
    client.getDoc('Customer', customerId),
    _getBalance(client, customerId),
  ]);

  final doc = results[0] as Map<String, dynamic>;
  doc['outstanding_balance'] = results[1];
  return doc;
});

Future<double> _getBalance(dynamic client, String customer) async {
  try {
    final result = await client.call(
      'erpnext.accounts.utils.get_balance_on',
      data: {
        'party_type': 'Customer',
        'party': customer,
      },
    );
    return (result ?? 0).toDouble();
  } catch (_) {
    return 0;
  }
}
