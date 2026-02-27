import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../model/material_request.dart';

/// Filter options for procurement list
enum ProcurementFilter {
  all,
  pendingMyAction,
  draft,
  pendingSupervisor,
  pendingPurchase,
  pendingFinance,
  paymentDone,
  received,
}

class ProcurementListState {
  final bool isLoading;
  final String? error;
  final List<MaterialRequest> requests;
  final int total;
  final bool hasMore;
  final ProcurementFilter filter;
  final String searchQuery;

  const ProcurementListState({
    this.isLoading = false,
    this.error,
    this.requests = const [],
    this.total = 0,
    this.hasMore = true,
    this.filter = ProcurementFilter.all,
    this.searchQuery = '',
  });

  ProcurementListState copyWith({
    bool? isLoading,
    String? error,
    List<MaterialRequest>? requests,
    int? total,
    bool? hasMore,
    ProcurementFilter? filter,
    String? searchQuery,
  }) {
    return ProcurementListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      requests: requests ?? this.requests,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ProcurementNotifier extends StateNotifier<ProcurementListState> {
  final Ref _ref;
  static const _pageSize = 30;

  ProcurementNotifier(this._ref) : super(const ProcurementListState()) {
    loadRequests();
  }

  List<List<dynamic>> _buildFilters() {
    final filters = <List<dynamic>>[];

    // Always filter for Purchase type
    filters.add(['material_request_type', '=', 'Purchase']);

    switch (state.filter) {
      case ProcurementFilter.draft:
        filters.add(['workflow_state', '=', 'Draft']);
        break;
      case ProcurementFilter.pendingSupervisor:
        filters.add(['workflow_state', '=', 'Pending Supervisor']);
        break;
      case ProcurementFilter.pendingPurchase:
        filters.add(['workflow_state', '=', 'Pending Purchase']);
        break;
      case ProcurementFilter.pendingFinance:
        filters.add(['workflow_state', '=', 'Pending Finance']);
        break;
      case ProcurementFilter.paymentDone:
        filters.add(['workflow_state', '=', 'Payment Done']);
        break;
      case ProcurementFilter.received:
        filters.add(['workflow_state', '=', 'Received']);
        break;
      case ProcurementFilter.pendingMyAction:
        // This is handled in the UI by checking the user's role
        // For now, filter non-draft and non-received
        filters.add(['workflow_state', 'not in', ['Draft', 'Received']]);
        break;
      case ProcurementFilter.all:
        break;
    }

    if (state.searchQuery.isNotEmpty) {
      filters.add(['custom_customer', 'like', '%${state.searchQuery}%']);
    }

    return filters;
  }

  static const _fields = [
    'name',
    'custom_customer',
    'material_request_type',
    'transaction_date',
    'schedule_date',
    'set_warehouse',
    'docstatus',
    'workflow_state',
    'custom_creator_role',
    'custom_whatsapp_source',
    'custom_rejection_reason',
    'transfer_number',
    'owner',
  ];

  Future<void> loadRequests({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      requests: refresh ? [] : state.requests,
    );
    final client = _ref.read(erpnextClientProvider);

    try {
      final filters = _buildFilters();

      final results = await Future.wait([
        client.getList(
          'Material Request',
          fields: _fields,
          filters: filters.isEmpty ? null : filters,
          orderBy: 'modified desc',
          limitPageLength: _pageSize,
          limitStart: 0,
        ),
        client.getCount(
          'Material Request',
          filters: filters.isEmpty ? null : filters,
        ),
      ]);

      final list = (results[0] as List)
          .map((j) => MaterialRequest.fromJson(j as Map<String, dynamic>))
          .toList();
      final total = results[1] as int;

      state = state.copyWith(
        isLoading: false,
        requests: list,
        total: total,
        hasMore: list.length < total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل طلبات الشراء',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final client = _ref.read(erpnextClientProvider);

    try {
      final filters = _buildFilters();
      final list = await client.getList(
        'Material Request',
        fields: _fields,
        filters: filters.isEmpty ? null : filters,
        orderBy: 'modified desc',
        limitPageLength: _pageSize,
        limitStart: state.requests.length,
      );

      final newRequests = list
          .map((j) => MaterialRequest.fromJson(j as Map<String, dynamic>))
          .toList();
      final all = [...state.requests, ...newRequests];

      state = state.copyWith(
        isLoading: false,
        requests: all,
        hasMore: all.length < state.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter(ProcurementFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter, requests: [], hasMore: true);
    loadRequests();
  }

  void search(String query) {
    state =
        state.copyWith(searchQuery: query.trim(), requests: [], hasMore: true);
    loadRequests();
  }

  /// Create a new Material Request
  Future<String> createRequest({
    required String? customer,
    required String scheduleDate,
    required String warehouse,
    required List<MaterialRequestItem> items,
    required String creatorRole,
    String? notes,
    String? whatsappSource,
  }) async {
    final client = _ref.read(erpnextClientProvider);
    final today = DateTime.now().toIso8601String().split('T').first;

    final data = <String, dynamic>{
      'material_request_type': 'Purchase',
      'transaction_date': today,
      'schedule_date': scheduleDate,
      'set_warehouse': warehouse,
      'custom_creator_role': creatorRole,
      if (customer != null && customer.isNotEmpty) 'custom_customer': customer,
      if (notes != null && notes.isNotEmpty) 'description': notes,
      if (whatsappSource != null && whatsappSource.isNotEmpty)
        'custom_whatsapp_source': whatsappSource,
      'items': items.map((i) => i.toJson()).toList(),
    };

    final result = await client.createDoc('Material Request', data);
    loadRequests(refresh: true);
    return result['name'] as String;
  }

  /// Apply a workflow action
  Future<void> applyWorkflowAction({
    required String requestName,
    required String action,
    String? rejectionReason,
    String? paymentReference,
  }) async {
    final client = _ref.read(erpnextClientProvider);

    // Update custom fields if provided
    if (rejectionReason != null || paymentReference != null) {
      await client.updateDoc('Material Request', requestName, {
        if (rejectionReason != null)
          'custom_rejection_reason': rejectionReason,
        if (paymentReference != null) 'transfer_number': paymentReference,
      });
    }

    // Frappe workflow API requires the full doc object, not just the name
    final doc = await client.getDoc('Material Request', requestName);

    await client.call(
      'frappe.model.workflow.apply_workflow',
      data: {
        'doc': doc,
        'action': action,
      },
    );

    loadRequests(refresh: true);
  }

  /// Update items (supervisor editing before approval)
  Future<void> updateItems({
    required String requestName,
    required List<MaterialRequestItem> items,
  }) async {
    final client = _ref.read(erpnextClientProvider);
    await client.updateDoc('Material Request', requestName, {
      'items': items.map((i) => i.toJson()).toList(),
    });
    loadRequests(refresh: true);
  }
}

final procurementProvider =
    StateNotifierProvider<ProcurementNotifier, ProcurementListState>((ref) {
  return ProcurementNotifier(ref);
});

/// Single request detail
final requestDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, requestId) async {
  final client = ref.read(erpnextClientProvider);
  return client.getDoc('Material Request', requestId);
});

/// Pending procurement count for dashboard badge
final pendingProcurementCountProvider = FutureProvider<int>((ref) async {
  final client = ref.read(erpnextClientProvider);
  return client.getCount('Material Request', filters: [
    ['material_request_type', '=', 'Purchase'],
    [
      'workflow_state',
      'not in',
      ['Draft', 'Received']
    ],
  ]);
});
