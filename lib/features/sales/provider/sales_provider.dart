import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../model/sales_invoice.dart';

/// Filter options
enum InvoiceFilter { all, draft, unpaid, paid, cancelled }

class SalesState {
  final bool isLoading;
  final String? error;
  final List<SalesInvoice> invoices;
  final int total;
  final bool hasMore;
  final InvoiceFilter filter;
  final String searchQuery;

  const SalesState({
    this.isLoading = false,
    this.error,
    this.invoices = const [],
    this.total = 0,
    this.hasMore = true,
    this.filter = InvoiceFilter.all,
    this.searchQuery = '',
  });

  SalesState copyWith({
    bool? isLoading,
    String? error,
    List<SalesInvoice>? invoices,
    int? total,
    bool? hasMore,
    InvoiceFilter? filter,
    String? searchQuery,
  }) {
    return SalesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      invoices: invoices ?? this.invoices,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class SalesNotifier extends StateNotifier<SalesState> {
  final Ref _ref;
  static const _pageSize = 30;

  SalesNotifier(this._ref) : super(const SalesState()) {
    loadInvoices();
  }

  List<List<dynamic>> _buildFilters() {
    final filters = <List<dynamic>>[];

    switch (state.filter) {
      case InvoiceFilter.draft:
        filters.add(['docstatus', '=', 0]);
        break;
      case InvoiceFilter.unpaid:
        filters.add(['docstatus', '=', 1]);
        filters.add(['outstanding_amount', '>', 0]);
        break;
      case InvoiceFilter.paid:
        filters.add(['docstatus', '=', 1]);
        filters.add(['outstanding_amount', '=', 0]);
        break;
      case InvoiceFilter.cancelled:
        filters.add(['docstatus', '=', 2]);
        break;
      case InvoiceFilter.all:
        break;
    }

    if (state.searchQuery.isNotEmpty) {
      filters.add(['customer_name', 'like', '%${state.searchQuery}%']);
    }

    return filters;
  }

  Future<void> loadInvoices({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      invoices: refresh ? [] : state.invoices,
    );
    final client = _ref.read(erpnextClientProvider);

    try {
      final filters = _buildFilters();

      final results = await Future.wait([
        client.getList(
          'Sales Invoice',
          fields: [
            'name',
            'customer',
            'customer_name',
            'posting_date',
            'grand_total',
            'outstanding_amount',
            'docstatus',
            'status',
            'currency',
            'sales_partner',
            'territory',
          ],
          filters: filters.isEmpty ? null : filters,
          orderBy: 'posting_date desc, name desc',
          limitPageLength: _pageSize,
          limitStart: 0,
        ),
        client.getCount('Sales Invoice', filters: filters.isEmpty ? null : filters),
      ]);

      final list = (results[0] as List)
          .map((j) => SalesInvoice.fromJson(j as Map<String, dynamic>))
          .toList();
      final total = results[1] as int;

      state = state.copyWith(
        isLoading: false,
        invoices: list,
        total: total,
        hasMore: list.length < total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل الفواتير',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final client = _ref.read(erpnextClientProvider);

    try {
      final list = await client.getList(
        'Sales Invoice',
        fields: [
          'name', 'customer', 'customer_name', 'posting_date',
          'grand_total', 'outstanding_amount', 'docstatus',
          'status', 'currency', 'sales_partner', 'territory',
        ],
        filters: _buildFilters().isEmpty ? null : _buildFilters(),
        orderBy: 'posting_date desc, name desc',
        limitPageLength: _pageSize,
        limitStart: state.invoices.length,
      );

      final newInvoices = list
          .map((j) => SalesInvoice.fromJson(j as Map<String, dynamic>))
          .toList();
      final all = [...state.invoices, ...newInvoices];

      state = state.copyWith(
        isLoading: false,
        invoices: all,
        hasMore: all.length < state.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter(InvoiceFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter, invoices: [], hasMore: true);
    loadInvoices();
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query.trim(), invoices: [], hasMore: true);
    loadInvoices();
  }
}

final salesProvider =
    StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  return SalesNotifier(ref);
});

/// Single invoice detail
final invoiceDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, invoiceId) async {
  final client = ref.read(erpnextClientProvider);
  return client.getDoc('Sales Invoice', invoiceId);
});
