import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/material_request.dart';
import '../model/workflow_action.dart';
import '../provider/procurement_provider.dart';
import 'widgets/workflow_state_badge.dart';
import 'widgets/workflow_stepper.dart';

class RequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(requestDetailProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: Text(requestId),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('فشل تحميل الطلب'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(requestDetailProvider(requestId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (data) =>
            _RequestDetailBody(data: data, requestId: requestId),
      ),
    );
  }
}

class _RequestDetailBody extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  final String requestId;

  const _RequestDetailBody({required this.data, required this.requestId});

  @override
  ConsumerState<_RequestDetailBody> createState() =>
      _RequestDetailBodyState();
}

class _RequestDetailBodyState extends ConsumerState<_RequestDetailBody> {
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = MaterialRequest.fromJson(widget.data);
    final items = (widget.data['items'] as List? ?? [])
        .map((i) => MaterialRequestItem.fromJson(i as Map<String, dynamic>))
        .toList();
    final actions = WorkflowAction.getActions(request.state);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Workflow stepper
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: WorkflowStepper(currentState: request.state),
                ),
              ),
              const SizedBox(height: 12),

              // Status header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      WorkflowStateBadge(
                        procurementState: request.state,
                        large: true,
                      ),
                      const SizedBox(height: 12),
                      if (request.customer != null &&
                          request.customer!.isNotEmpty)
                        Text(
                          request.customer!,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Info card
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(request.transactionDate),
                      subtitle: const Text('تاريخ الطلب'),
                    ),
                    if (request.scheduleDate != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(request.scheduleDate!),
                        subtitle: const Text('تاريخ التسليم المطلوب'),
                      ),
                    ],
                    if (request.setWarehouse != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.warehouse),
                        title: Text(request.setWarehouse!),
                        subtitle: const Text('المستودع'),
                      ),
                    ],
                    if (request.ownerName != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(request.ownerName!),
                        subtitle: Text(
                          'المنشئ${request.customCreatorRole != null ? ' (${request.customCreatorRole})' : ''}',
                        ),
                      ),
                    ],
                    if (request.hasWhatsappSource) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.chat, color: Colors.green[700]),
                        title: Text(request.customWhatsappSource!),
                        subtitle: const Text('مصدر واتساب'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Items card
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
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...items.map((item) => _ItemRow(item: item)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Rejection reason
              if (request.isRejected &&
                  request.customRejectionReason != null &&
                  request.customRejectionReason!.isNotEmpty)
                Card(
                  color: Colors.red[50],
                  child: ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red[700]),
                    title: const Text('سبب الرفض'),
                    subtitle: Text(request.customRejectionReason!),
                  ),
                ),

              // Payment reference (transfer_number)
              if (request.transferNumber != null &&
                  request.transferNumber!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.teal[50],
                  child: ListTile(
                    leading: Icon(Icons.payment, color: Colors.teal[700]),
                    title: const Text('رقم الحوالة'),
                    subtitle: Text(request.transferNumber!),
                  ),
                ),
              ],

              // WhatsApp verification
              if (request.customWhatsappVerification != null &&
                  request.customWhatsappVerification!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.blue[50],
                  child: ListTile(
                    leading: Icon(Icons.verified, color: Colors.blue[700]),
                    title: const Text('مراجعة واتساب'),
                    subtitle: Text(request.customWhatsappVerification!),
                  ),
                ),
              ],

              // Receipt notes
              if (request.customReceiptNotes != null &&
                  request.customReceiptNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.green[50],
                  child: ListTile(
                    leading:
                        Icon(Icons.inventory, color: Colors.green[700]),
                    title: const Text('ملاحظات الاستلام'),
                    subtitle: Text(request.customReceiptNotes!),
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),

        // Action buttons at bottom
        if (actions.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: actions.map((action) {
                  if (action.isRejection) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: OutlinedButton(
                          onPressed: _isActionLoading
                              ? null
                              : () => _showRejectDialog(action),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: Text(action.label),
                        ),
                      ),
                    );
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton(
                        onPressed: _isActionLoading
                            ? null
                            : () => _handleAction(action, request.state),
                        child: _isActionLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(action.label),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleAction(
      WorkflowAction action, ProcurementState currentState) async {
    // If finance approval, ask for payment reference
    if (currentState == ProcurementState.pendingFinance &&
        action.isApproval) {
      _showPaymentReferenceDialog(action);
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      await ref.read(procurementProvider.notifier).applyWorkflowAction(
            requestName: widget.requestId,
            action: action.action,
          );
      ref.invalidate(requestDetailProvider(widget.requestId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تطبيق: ${action.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showRejectDialog(WorkflowAction action) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'اكتب سبب الرفض...',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isActionLoading = true);
              try {
                await ref
                    .read(procurementProvider.notifier)
                    .applyWorkflowAction(
                      requestName: widget.requestId,
                      action: action.action,
                      rejectionReason: reasonController.text.trim(),
                    );
                ref.invalidate(requestDetailProvider(widget.requestId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الرفض')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isActionLoading = false);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  void _showPaymentReferenceDialog(WorkflowAction action) {
    final refController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مرجع الحوالة'),
        content: TextField(
          controller: refController,
          decoration: const InputDecoration(
            hintText: 'أدخل رقم الحوالة أو المرجع...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isActionLoading = true);
              try {
                await ref
                    .read(procurementProvider.notifier)
                    .applyWorkflowAction(
                      requestName: widget.requestId,
                      action: action.action,
                      paymentReference: refController.text.trim(),
                    );
                ref.invalidate(requestDetailProvider(widget.requestId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الموافقة والدفع')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isActionLoading = false);
              }
            },
            child: const Text('موافقة'),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final MaterialRequestItem item;
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
                  item.itemName.isNotEmpty ? item.itemName : item.itemCode,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.qty.toStringAsFixed(0)}${item.uom != null ? ' ${item.uom}' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (item.itemCode.isNotEmpty)
            Text(
              item.itemCode,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }
}
