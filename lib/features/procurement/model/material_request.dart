/// Procurement workflow states (matching ERPNext "Purchase Request Approval" workflow)
enum ProcurementState {
  draft('Draft', 'مسودة'),
  pendingSupervisor('Pending Supervisor', 'بانتظار المشرف'),
  pendingPurchase('Pending Purchase', 'بانتظار المشتريات'),
  pendingFinance('Pending Finance', 'بانتظار المالية'),
  paymentDone('Payment Done', 'تم الدفع'),
  pendingExecution('Pending Execution', 'بانتظار التنفيذ'),
  received('Received', 'تم الاستلام'),
  rejected('Rejected', 'مرفوض');

  final String value;
  final String label;
  const ProcurementState(this.value, this.label);

  static ProcurementState fromValue(String? value) {
    if (value == null || value.isEmpty) return ProcurementState.draft;
    return ProcurementState.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ProcurementState.draft,
    );
  }

  /// Order index for stepper progress (rejected maps to -1)
  int get stepIndex {
    if (this == rejected) return -1;
    return index;
  }
}

/// Material Request model matching ERPNext Material Request DocType
class MaterialRequest {
  final String name;
  final String? customer;
  final String materialRequestType;
  final String transactionDate;
  final String? scheduleDate;
  final String? setWarehouse;
  final int docstatus;
  final String? workflowState;
  final String? customCreatorRole;
  final String? customWhatsappSource;
  final String? customWhatsappVerification;
  final String? customRejectionReason;
  final String? transferNumber;
  final String? customReceiptNotes;
  final String? owner;
  final String? ownerName;
  final double? totalQty;

  const MaterialRequest({
    required this.name,
    this.customer,
    this.materialRequestType = 'Purchase',
    required this.transactionDate,
    this.scheduleDate,
    this.setWarehouse,
    this.docstatus = 0,
    this.workflowState,
    this.customCreatorRole,
    this.customWhatsappSource,
    this.customWhatsappVerification,
    this.customRejectionReason,
    this.transferNumber,
    this.customReceiptNotes,
    this.owner,
    this.ownerName,
    this.totalQty,
  });

  factory MaterialRequest.fromJson(Map<String, dynamic> json) {
    return MaterialRequest(
      name: json['name'] as String,
      customer: json['custom_customer'] as String?,
      materialRequestType:
          json['material_request_type'] as String? ?? 'Purchase',
      transactionDate: json['transaction_date'] as String? ?? '',
      scheduleDate: json['schedule_date'] as String?,
      setWarehouse: json['set_warehouse'] as String?,
      docstatus: (json['docstatus'] ?? 0) as int,
      workflowState: json['workflow_state'] as String?,
      customCreatorRole: json['custom_creator_role'] as String?,
      customWhatsappSource: json['custom_whatsapp_source'] as String?,
      customWhatsappVerification:
          json['custom_whatsapp_verification'] as String?,
      customRejectionReason: json['custom_rejection_reason'] as String?,
      transferNumber: json['transfer_number'] as String?,
      customReceiptNotes: json['custom_receipt_notes'] as String?,
      owner: json['owner'] as String?,
      ownerName: json['owner_name'] as String?,
      totalQty: json['total_qty'] != null ? (json['total_qty']).toDouble() : null,
    );
  }

  ProcurementState get state => ProcurementState.fromValue(workflowState);

  bool get isDraft => state == ProcurementState.draft;
  bool get isRejected => state == ProcurementState.rejected;
  bool get isReceived => state == ProcurementState.received;
  bool get hasWhatsappSource =>
      customWhatsappSource != null && customWhatsappSource!.isNotEmpty;
}

/// Material Request Item
class MaterialRequestItem {
  final String itemCode;
  final String itemName;
  final double qty;
  final String? uom;
  final String? warehouse;
  final String? scheduleDate;

  const MaterialRequestItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    this.uom,
    this.warehouse,
    this.scheduleDate,
  });

  factory MaterialRequestItem.fromJson(Map<String, dynamic> json) {
    return MaterialRequestItem(
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      uom: json['uom'] as String?,
      warehouse: json['warehouse'] as String?,
      scheduleDate: json['schedule_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'qty': qty,
      if (uom != null) 'uom': uom,
      if (warehouse != null) 'warehouse': warehouse,
      if (scheduleDate != null) 'schedule_date': scheduleDate,
    };
  }
}
