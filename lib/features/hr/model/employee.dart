/// Employee model matching ERPNext Employee DocType
class Employee {
  final String name; // Employee ID (e.g. "HR-EMP-00001")
  final String employeeName;
  final String? designation;
  final String? department;
  final String? branch;
  final String status; // Active, Inactive, Suspended, Left
  final String? image;
  final String? dateOfJoining;
  final String? validUpto; // Iqama expiry
  final String? userId;
  final String? gender;
  final String? cellPhone;
  final String? personalPhone;
  final String? companyEmail;

  const Employee({
    required this.name,
    required this.employeeName,
    this.designation,
    this.department,
    this.branch,
    this.status = 'Active',
    this.image,
    this.dateOfJoining,
    this.validUpto,
    this.userId,
    this.gender,
    this.cellPhone,
    this.personalPhone,
    this.companyEmail,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'] as String,
      employeeName: json['employee_name'] as String? ?? json['name'] as String,
      designation: json['designation'] as String?,
      department: json['department'] as String?,
      branch: json['branch'] as String?,
      status: json['status'] as String? ?? 'Active',
      image: json['image'] as String?,
      dateOfJoining: json['date_of_joining'] as String?,
      validUpto: json['valid_upto'] as String?,
      userId: json['user_id'] as String?,
      gender: json['gender'] as String?,
      cellPhone: json['cell_phone'] as String?,
      personalPhone: json['personal_phone'] as String?,
      companyEmail: json['company_email'] as String?,
    );
  }

  /// Whether this employee can connect WhatsApp (has a cell phone number)
  bool get canConnectWhatsApp =>
      cellPhone != null && cellPhone!.isNotEmpty;

  /// WhatsApp session name: phone number stripped of non-digits
  /// e.g. +966555339356 → 966555339356
  String? get sessionName {
    if (!canConnectWhatsApp) return null;
    return cellPhone!.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// First letter for avatar
  String get initial =>
      employeeName.isNotEmpty ? employeeName.substring(0, 1) : '?';

  bool get isActive => status == 'Active';

  /// Check if iqama expires within 30 days
  bool get hasExpiringSoon {
    if (validUpto == null || validUpto!.isEmpty) return false;
    try {
      final expiry = DateTime.parse(validUpto!);
      final daysLeft = expiry.difference(DateTime.now()).inDays;
      return daysLeft >= 0 && daysLeft <= 30;
    } catch (_) {
      return false;
    }
  }

  /// Check if iqama is already expired
  bool get isExpired {
    if (validUpto == null || validUpto!.isEmpty) return false;
    try {
      final expiry = DateTime.parse(validUpto!);
      return expiry.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Days until iqama expiry (negative = expired)
  int? get daysUntilExpiry {
    if (validUpto == null || validUpto!.isEmpty) return null;
    try {
      final expiry = DateTime.parse(validUpto!);
      return expiry.difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'Active':
        return 'نشط';
      case 'Inactive':
        return 'غير نشط';
      case 'Suspended':
        return 'موقوف';
      case 'Left':
        return 'مستقيل';
      default:
        return status;
    }
  }

  String get genderLabel {
    switch (gender) {
      case 'Male':
        return 'ذكر';
      case 'Female':
        return 'أنثى';
      default:
        return gender ?? '';
    }
  }
}
