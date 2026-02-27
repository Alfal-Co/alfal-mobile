import 'package:flutter/material.dart';
import '../../model/material_request.dart';

class WorkflowStepper extends StatelessWidget {
  final ProcurementState currentState;

  const WorkflowStepper({super.key, required this.currentState});

  static const _steps = [
    (ProcurementState.draft, 'مسودة', Icons.edit_note),
    (ProcurementState.pendingSupervisor, 'المشرف', Icons.supervisor_account),
    (ProcurementState.pendingPurchase, 'المشتريات', Icons.shopping_cart),
    (ProcurementState.pendingFinance, 'المالية', Icons.account_balance),
    (ProcurementState.paymentDone, 'الدفع', Icons.payment),
    (ProcurementState.received, 'الاستلام', Icons.check_circle),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = currentState.stepIndex;

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          final (state, label, icon) = _steps[index];
          final stepIndex = state.stepIndex;
          final isCompleted = currentIndex > stepIndex;
          final isCurrent = currentState == state ||
              // Handle intermediate states not in the stepper list
              (currentIndex > stepIndex &&
                  index < _steps.length - 1 &&
                  currentIndex < _steps[index + 1].$1.stepIndex);

          Color circleColor;
          Color iconColor;
          Color textColor;

          if (isCompleted) {
            circleColor = theme.colorScheme.primary;
            iconColor = Colors.white;
            textColor = theme.colorScheme.primary;
          } else if (isCurrent) {
            circleColor = theme.colorScheme.primary;
            iconColor = Colors.white;
            textColor = theme.colorScheme.primary;
          } else {
            circleColor = Colors.grey[200]!;
            iconColor = Colors.grey[400]!;
            textColor = Colors.grey[400]!;
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: circleColor,
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (index < _steps.length - 1)
                Container(
                  width: 24,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: isCompleted ? theme.colorScheme.primary : Colors.grey[300],
                ),
            ],
          );
        },
      ),
    );
  }
}
