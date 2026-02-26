import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../model/payment_entry.dart';

enum PaymentFilter { all, submitted, draft, cancelled }

class PaymentsState {
  final bool isLoading;
  final String? error;
  final List<PaymentEntry> payments;
  final int total;
  final bool hasMore;
  final PaymentFilter filter;
  final String searchQuery;
  final double todayTotal;

  const PaymentsState({
    this.isLoading = false,
    this.error,
    this.payments = const [],
    this.total = 0,
    this.hasMore = true,
    this.filter = PaymentFilter.all,
    this.searchQuery = '',
    this.todayTotal = 0,
  });

  PaymentsState copyWith({
    bool? isLoading,
    String? error,
    List<PaymentEntry>? payments,
    int? total,
    bool? hasMore,
    PaymentFilter? filter,
    String? searchQuery,
    double? todayTotal,
  }) {
    return PaymentsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      payments: payments ?? this.payments,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      todayTotal: todayTotal ?? this.todayTotal,
    );
  }
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final Ref _ref;
  static const _pageSize = 30;

  PaymentsNotifier(this._ref) : super(const PaymentsState()) {
    loadPayments();
  }

  List<List<dynamic>> _buildFilters() {
    final filters = <List<dynamic>>[
      ['payment_type', '=', 'Receive'],
    ];

    switch (state.filter) {
      case PaymentFilter.submitted:
        filters.add(['docstatus', '=', 1]);
        break;
      case PaymentFilter.draft:
        filters.add(['docstatus', '=', 0]);
        break;
      case PaymentFilter.cancelled:
        filters.add(['docstatus', '=', 2]);
        break;
      case PaymentFilter.all:
        break;
    }

    if (state.searchQuery.isNotEmpty) {
      filters.add(['party_name', 'like', '%${state.searchQuery}%']);
    }

    return filters;
  }

  Future<void> loadPayments({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      payments: refresh ? [] : state.payments,
    );
    final client = _ref.read(erpnextClientProvider);

    try {
      final filters = _buildFilters();

      final results = await Future.wait([
        client.getList(
          'Payment Entry',
          fields: [
            'name', 'payment_type', 'party_type', 'party', 'party_name',
            'posting_date', 'paid_amount', 'mode_of_payment',
            'reference_no', 'reference_date', 'docstatus', 'status',
            'paid_from', 'paid_to',
          ],
          filters: filters,
          orderBy: 'posting_date desc, name desc',
          limitPageLength: _pageSize,
          limitStart: 0,
        ),
        client.getCount('Payment Entry', filters: filters),
        _getTodayTotal(client),
      ]);

      final list = (results[0] as List)
          .map((j) => PaymentEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      final total = results[1] as int;
      final todayTotal = results[2] as double;

      state = state.copyWith(
        isLoading: false,
        payments: list,
        total: total,
        hasMore: list.length < total,
        todayTotal: todayTotal,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل التحصيلات',
      );
    }
  }

  Future<double> _getTodayTotal(dynamic client) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final list = await client.getList(
        'Payment Entry',
        fields: ['paid_amount'],
        filters: [
          ['payment_type', '=', 'Receive'],
          ['posting_date', '=', today],
          ['docstatus', '=', 1],
        ],
        limitPageLength: 0,
      );
      double total = 0;
      for (final p in list) {
        total += (p['paid_amount'] ?? 0).toDouble();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final client = _ref.read(erpnextClientProvider);

    try {
      final list = await client.getList(
        'Payment Entry',
        fields: [
          'name', 'payment_type', 'party_type', 'party', 'party_name',
          'posting_date', 'paid_amount', 'mode_of_payment',
          'reference_no', 'reference_date', 'docstatus', 'status',
          'paid_from', 'paid_to',
        ],
        filters: _buildFilters(),
        orderBy: 'posting_date desc, name desc',
        limitPageLength: _pageSize,
        limitStart: state.payments.length,
      );

      final newPayments = list
          .map((j) => PaymentEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      final all = [...state.payments, ...newPayments];

      state = state.copyWith(
        isLoading: false,
        payments: all,
        hasMore: all.length < state.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter(PaymentFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter, payments: [], hasMore: true);
    loadPayments();
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query.trim(), payments: [], hasMore: true);
    loadPayments();
  }
}

final paymentsProvider =
    StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  return PaymentsNotifier(ref);
});

/// Single payment detail
final paymentDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, paymentId) async {
  final client = ref.read(erpnextClientProvider);
  return client.getDoc('Payment Entry', paymentId);
});
