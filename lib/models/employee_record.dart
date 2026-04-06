/// One employee row from attendance get-employees API.
class EmployeeRecord {
  const EmployeeRecord({
    required this.id,
    required this.empId,
    required this.empCode,
    required this.fullName,
    this.status,
    this.departmentName,
    this.designationName,
  });

  final String id;
  final int? empId;
  final String empCode;
  final String fullName;
  final String? status;
  final String? departmentName;
  final String? designationName;

  factory EmployeeRecord.fromJson(Map<String, dynamic> json) {
    final workplace = json['workplace_details'];
    return EmployeeRecord(
      id: json['_id']?.toString() ?? '',
      empId: json['EmpId'] is int
          ? json['EmpId'] as int
          : int.tryParse('${json['EmpId']}'),
      empCode: json['emp_code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      status: json['status']?.toString(),
      departmentName: workplace is Map<String, dynamic>
          ? workplace['department_name']?.toString()
          : null,
      designationName: workplace is Map<String, dynamic>
          ? workplace['designation_name']?.toString()
          : null,
    );
  }
}

class EmployeesListResult {
  const EmployeesListResult({
    required this.status,
    required this.success,
    required this.total,
    required this.employees,
  });

  final String status;
  final bool success;
  final int total;
  final List<EmployeeRecord> employees;

  bool get isSuccess => status == 'Success' && success;
}
