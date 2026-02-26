/// Customer model matching ERPNext Customer DocType
class Customer {
  final String name; // Customer ID (e.g. "CUST-0001")
  final String customerName;
  final String? customerGroup;
  final String? territory;
  final String? mobileNo;
  final String? emailId;
  final String? customerType;
  final double outstandingBalance;
  final bool disabled;

  const Customer({
    required this.name,
    required this.customerName,
    this.customerGroup,
    this.territory,
    this.mobileNo,
    this.emailId,
    this.customerType,
    this.outstandingBalance = 0,
    this.disabled = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] as String,
      customerName: json['customer_name'] as String? ?? json['name'] as String,
      customerGroup: json['customer_group'] as String?,
      territory: json['territory'] as String?,
      mobileNo: json['mobile_no'] as String?,
      emailId: json['email_id'] as String?,
      customerType: json['customer_type'] as String?,
      outstandingBalance: (json['outstanding_balance'] ?? 0).toDouble(),
      disabled: (json['disabled'] ?? 0) == 1,
    );
  }

  /// First letter for avatar
  String get initial =>
      customerName.isNotEmpty ? customerName.substring(0, 1) : '?';
}
