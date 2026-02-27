import 'material_request.dart';

/// Available workflow actions matching ERPNext "Purchase Request Approval" workflow
class WorkflowAction {
  final String action;
  final String label;
  final bool isApproval;
  final bool isRejection;

  const WorkflowAction({
    required this.action,
    required this.label,
    this.isApproval = false,
    this.isRejection = false,
  });

  /// Get available actions for the current state
  /// Action names match exactly what ERPNext workflow expects
  static List<WorkflowAction> getActions(ProcurementState currentState) {
    switch (currentState) {
      case ProcurementState.draft:
        return const [
          WorkflowAction(
            action: 'Submit to Supervisor',
            label: 'إرسال للمشرف',
            isApproval: true,
          ),
        ];
      case ProcurementState.pendingSupervisor:
        return const [
          WorkflowAction(
            action: 'Approve',
            label: 'موافقة',
            isApproval: true,
          ),
          WorkflowAction(
            action: 'Reject',
            label: 'رفض',
            isRejection: true,
          ),
        ];
      case ProcurementState.pendingPurchase:
        return const [
          WorkflowAction(
            action: 'Approve',
            label: 'موافقة وإرسال للمالية',
            isApproval: true,
          ),
          WorkflowAction(
            action: 'Reject',
            label: 'رفض',
            isRejection: true,
          ),
        ];
      case ProcurementState.pendingFinance:
        return const [
          WorkflowAction(
            action: 'Confirm Payment',
            label: 'تأكيد الدفع',
            isApproval: true,
          ),
          WorkflowAction(
            action: 'Reject',
            label: 'رفض',
            isRejection: true,
          ),
        ];
      case ProcurementState.paymentDone:
        return const [
          WorkflowAction(
            action: 'Send to Purchase',
            label: 'إرسال للتنفيذ',
            isApproval: true,
          ),
        ];
      case ProcurementState.pendingExecution:
        return const [
          WorkflowAction(
            action: 'Confirm Execution',
            label: 'تأكيد الاستلام',
            isApproval: true,
          ),
        ];
      case ProcurementState.received:
        return const [];
      case ProcurementState.rejected:
        return const [];
    }
  }

  /// Check if a state allows editing items (supervisor can modify before approving)
  static bool canEditItems(ProcurementState state) {
    return state == ProcurementState.pendingSupervisor ||
        state == ProcurementState.pendingPurchase;
  }
}
