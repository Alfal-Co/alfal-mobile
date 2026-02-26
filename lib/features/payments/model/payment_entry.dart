import 'package:flutter/material.dart';

/// Payment Entry model matching ERPNext Payment Entry DocType
class PaymentEntry {
  final String name;
  final String paymentType; // Receive, Pay, Internal Transfer
  final String partyType;
  final String party;
  final String partyName;
  final String postingDate;
  final double paidAmount;
  final String modeOfPayment;
  final String? referenceNo;
  final String? referenceDate;
  final int docstatus;
  final String? status;
  final String? paidFrom;
  final String? paidTo;

  const PaymentEntry({
    required this.name,
    required this.paymentType,
    required this.partyType,
    required this.party,
    required this.partyName,
    required this.postingDate,
    required this.paidAmount,
    required this.modeOfPayment,
    this.referenceNo,
    this.referenceDate,
    this.docstatus = 0,
    this.status,
    this.paidFrom,
    this.paidTo,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      name: json['name'] as String,
      paymentType: json['payment_type'] as String? ?? '',
      partyType: json['party_type'] as String? ?? '',
      party: json['party'] as String? ?? '',
      partyName: json['party_name'] as String? ?? '',
      postingDate: json['posting_date'] as String? ?? '',
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      modeOfPayment: json['mode_of_payment'] as String? ?? '',
      referenceNo: json['reference_no'] as String?,
      referenceDate: json['reference_date'] as String?,
      docstatus: (json['docstatus'] ?? 0) as int,
      status: json['status'] as String?,
      paidFrom: json['paid_from'] as String?,
      paidTo: json['paid_to'] as String?,
    );
  }

  bool get isDraft => docstatus == 0;
  bool get isSubmitted => docstatus == 1;
  bool get isCancelled => docstatus == 2;
  bool get isReceive => paymentType == 'Receive';

  String get statusLabel {
    if (isCancelled) return 'ملغية';
    if (isDraft) return 'مسودة';
    return 'مقبوضة';
  }

  String get modeLabel {
    switch (modeOfPayment) {
      case 'Cash':
        return 'نقد';
      case 'Bank Transfer':
        return 'تحويل بنكي';
      case 'Credit Card':
        return 'شبكة';
      case 'Cheque':
        return 'شيك';
      default:
        return modeOfPayment;
    }
  }

  IconData get modeIcon {
    switch (modeOfPayment) {
      case 'Cash':
        return Icons.payments;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Credit Card':
        return Icons.credit_card;
      case 'Cheque':
        return Icons.description;
      default:
        return Icons.payment;
    }
  }
}
