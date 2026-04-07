class VisitorLogRecord {
  const VisitorLogRecord({
    required this.visitId,
    required this.visitorId,
    required this.inwardAt,
    required this.reason,
    required this.hasEmployeeApproved,
    required this.isEntryAllowed,
    required this.unit,
    required this.employeeId,
    required this.countOfVisitors,
    required this.otp,
    required this.visitorName,
    required this.employeeName,
    required this.employeeCode,
    this.outwardAt,
    this.visitorPhone,
    this.visitorPhoto,
  });

  final String visitId;
  final String visitorId;
  final String inwardAt;
  final String reason;
  final bool hasEmployeeApproved;
  final bool isEntryAllowed;
  final String unit;
  final String employeeId;
  final String countOfVisitors;
  final String otp;
  final String visitorName;
  final String employeeName;
  final String employeeCode;
  final String? outwardAt;
  final String? visitorPhone;
  final List<String>? visitorPhoto;

  factory VisitorLogRecord.fromJson(Map<String, dynamic> json) {
    List<String>? photos;
    final rawPhotos = json['visitor_photo'];
    if (rawPhotos is List) {
      photos = rawPhotos.map((e) => e.toString()).toList(growable: false);
    }

    return VisitorLogRecord(
      visitId: json['visit_id']?.toString() ?? '',
      visitorId: json['visitor_id']?.toString() ?? '',
      inwardAt: json['inward_at']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      hasEmployeeApproved: json['has_employee_approved'] == true,
      isEntryAllowed: json['is_entry_allowed'] == true,
      unit: json['unit']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      countOfVisitors: json['count_of_visitors']?.toString() ?? '',
      otp: json['otp']?.toString() ?? '',
      visitorName: json['visitor_name']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      employeeCode: json['employee_code']?.toString() ?? '',
      outwardAt: json['outward_at']?.toString(),
      visitorPhone: json['visitor_phone']?.toString(),
      visitorPhoto: photos,
    );
  }
}

class VisitorLogsListResult {
  const VisitorLogsListResult({
    required this.status,
    required this.logs,
    required this.totalCount,
  });

  final String status;
  final List<VisitorLogRecord> logs;
  final int totalCount;

  bool get isSuccess => status == 'Success';
}
