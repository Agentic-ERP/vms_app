class CreateVisitorLogRequest {
  const CreateVisitorLogRequest({
    required this.visitorId,
    required this.reason,
    required this.employeeName,
    required this.visitorName,
    required this.employeeCode,
    required this.hasEmployeeApproved,
    required this.isEntryAllowed,
    required this.unit,
    required this.employeeId,
    required this.countOfVisitors,
  });

  final String visitorId;
  final String reason;
  final String employeeName;
  final String visitorName;
  final String employeeCode;
  final bool hasEmployeeApproved;
  final bool isEntryAllowed;
  final String unit;
  final String employeeId;
  final String countOfVisitors;

  Map<String, dynamic> toJson() => {
        'visitor_id': visitorId,
        'reason': reason,
        'employee_name': employeeName,
        'visitor_name': visitorName,
        'employee_code': employeeCode,
        'has_employee_approved': hasEmployeeApproved,
        'is_entry_allowed': isEntryAllowed,
        'unit': unit,
        'employee_id': employeeId,
        'count_of_visitors': countOfVisitors,
      };
}

class CreateVisitorLogResponse {
  const CreateVisitorLogResponse({
    required this.status,
    required this.raw,
  });

  final String status;
  final Map<String, dynamic> raw;

  bool get isSuccess {
    final normalized = status.trim().toLowerCase();
    return normalized == 'success' || normalized.contains('success');
  }
}
