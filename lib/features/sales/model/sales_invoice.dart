/// Sales Invoice model matching ERPNext Sales Invoice DocType
class SalesInvoice {
  final String name;
  final String customer;
  final String customerName;
  final String postingDate;
  final double grandTotal;
  final double outstandingAmount;
  final int docstatus; // 0=Draft, 1=Submitted, 2=Cancelled
  final String? status;
  final String? currency;
  final String? salesPartner;
  final String? territory;

  const SalesInvoice({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.postingDate,
    required this.grandTotal,
    required this.outstandingAmount,
    this.docstatus = 0,
    this.status,
    this.currency,
    this.salesPartner,
    this.territory,
  });

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    return SalesInvoice(
      name: json['name'] as String,
      customer: json['customer'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      postingDate: json['posting_date'] as String? ?? '',
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      outstandingAmount: (json['outstanding_amount'] ?? 0).toDouble(),
      docstatus: (json['docstatus'] ?? 0) as int,
      status: json['status'] as String?,
      currency: json['currency'] as String?,
      salesPartner: json['sales_partner'] as String?,
      territory: json['territory'] as String?,
    );
  }

  bool get isDraft => docstatus == 0;
  bool get isSubmitted => docstatus == 1;
  bool get isCancelled => docstatus == 2;
  bool get isPaid => outstandingAmount == 0 && isSubmitted;
  bool get isOverdue => outstandingAmount > 0 && isSubmitted;

  String get statusLabel {
    if (isCancelled) return 'ملغية';
    if (isDraft) return 'مسودة';
    if (isPaid) return 'مدفوعة';
    if (isOverdue) return 'غير مدفوعة';
    return status ?? '';
  }
}

/// Sales Invoice Item
class SalesInvoiceItem {
  final String itemCode;
  final String itemName;
  final double qty;
  final double rate;
  final double amount;
  final String? uom;

  const SalesInvoiceItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
    this.uom,
  });

  factory SalesInvoiceItem.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceItem(
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      uom: json['uom'] as String?,
    );
  }
}
