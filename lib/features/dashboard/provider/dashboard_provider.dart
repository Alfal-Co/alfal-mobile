import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';

/// Dashboard data state
class DashboardData {
  final bool isLoading;
  final String? error;
  final int totalCustomers;
  final int todayInvoices;
  final double todaySales;
  final int totalSuppliers;
  final int pendingProcurement;

  const DashboardData({
    this.isLoading = true,
    this.error,
    this.totalCustomers = 0,
    this.todayInvoices = 0,
    this.todaySales = 0,
    this.totalSuppliers = 0,
    this.pendingProcurement = 0,
  });

  DashboardData copyWith({
    bool? isLoading,
    String? error,
    int? totalCustomers,
    int? todayInvoices,
    double? todaySales,
    int? totalSuppliers,
    int? pendingProcurement,
  }) {
    return DashboardData(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      todayInvoices: todayInvoices ?? this.todayInvoices,
      todaySales: todaySales ?? this.todaySales,
      totalSuppliers: totalSuppliers ?? this.totalSuppliers,
      pendingProcurement: pendingProcurement ?? this.pendingProcurement,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardData> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(const DashboardData()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    final client = _ref.read(erpnextClientProvider);

    try {
      // Fetch counts in parallel
      final results = await Future.wait([
        client.getCount('Customer'),
        client.getCount('Supplier'),
        _getTodayInvoiceCount(client),
        _getTodaySalesTotal(client),
        _getPendingProcurementCount(client),
      ]);

      state = state.copyWith(
        isLoading: false,
        totalCustomers: results[0] as int,
        totalSuppliers: results[1] as int,
        todayInvoices: results[2] as int,
        todaySales: results[3] as double,
        pendingProcurement: results[4] as int,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل البيانات: ${e.toString()}',
      );
    }
  }

  Future<int> _getTodayInvoiceCount(dynamic client) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      return await client.getCount(
        'Sales Invoice',
        filters: [
          ['posting_date', '=', today],
          ['docstatus', '=', 1],
        ],
      );
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getPendingProcurementCount(dynamic client) async {
    try {
      return await client.getCount(
        'Material Request',
        filters: [
          ['material_request_type', '=', 'Purchase'],
          ['workflow_state', 'not in', ['Draft', 'Received']],
        ],
      );
    } catch (_) {
      return 0;
    }
  }

  Future<double> _getTodaySalesTotal(dynamic client) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final invoices = await client.getList(
        'Sales Invoice',
        fields: ['grand_total'],
        filters: [
          ['posting_date', '=', today],
          ['docstatus', '=', 1],
        ],
        limitPageLength: 0,
      );
      double total = 0;
      for (final inv in invoices) {
        total += (inv['grand_total'] ?? 0).toDouble();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardData>((ref) {
  return DashboardNotifier(ref);
});
