import 'package:flutter/material.dart';
import '../../model/material_request.dart';

class WorkflowStateBadge extends StatelessWidget {
  final ProcurementState procurementState;
  final bool large;

  const WorkflowStateBadge({
    super.key,
    required this.procurementState,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _getStyle();

    if (large) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              procurementState.label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        procurementState.label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color, IconData) _getStyle() {
    switch (procurementState) {
      case ProcurementState.draft:
        return (Colors.grey[100]!, Colors.grey[700]!, Icons.edit_note);
      case ProcurementState.pendingSupervisor:
        return (
          Colors.amber[50]!,
          Colors.amber[800]!,
          Icons.supervisor_account
        );
      case ProcurementState.pendingPurchase:
        return (Colors.blue[50]!, Colors.blue[700]!, Icons.shopping_cart);
      case ProcurementState.pendingFinance:
        return (Colors.purple[50]!, Colors.purple[700]!, Icons.account_balance);
      case ProcurementState.paymentDone:
        return (Colors.teal[50]!, Colors.teal[700]!, Icons.payment);
      case ProcurementState.pendingExecution:
        return (Colors.indigo[50]!, Colors.indigo[700]!, Icons.local_shipping);
      case ProcurementState.received:
        return (Colors.green[50]!, Colors.green[700]!, Icons.check_circle);
      case ProcurementState.rejected:
        return (Colors.red[50]!, Colors.red[700]!, Icons.cancel);
    }
  }
}
