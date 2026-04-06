import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_record.dart';
import '../models/employees_query_params.dart';
import '../services/employees_api_service.dart';
import 'employees_api_service_provider.dart';
import 'visitor_session_provider.dart';

bool _matchesFilter(EmployeeRecord e, String field, String operator, String value) {
  final needle = value.trim().toLowerCase();
  if (needle.isEmpty) return true;

  String haystack;
  switch (field) {
    case 'full_name':
      haystack = e.fullName;
    case 'emp_code':
      haystack = e.empCode;
    case 'department_name':
      haystack = e.departmentName ?? '';
    case 'designation_name':
      haystack = e.designationName ?? '';
    default:
      return true;
  }

  final source = haystack.toLowerCase();
  switch (operator) {
    case 'equals':
      return source == needle;
    case 'contains':
    default:
      return source.contains(needle);
  }
}

/// Fetches employee list and applies local client-side filters.
final employeesListProvider =
    FutureProvider.autoDispose.family<EmployeesListResult, EmployeesQueryParams>(
  (ref, params) async {
    final service = ref.watch(employeesApiServiceProvider);
    final cookieHeader = ref.watch(hrCookieHeaderProvider);

    final result = await service.fetchEmployees(
      params: params,
      cookieHeader: cookieHeader,
    );
    if (!result.isSuccess) {
      throw EmployeesApiException('API Status: ${result.status}');
    }

    if (params.localFilters.isEmpty) return result;

    final filtered = result.employees.where((employee) {
      for (final f in params.localFilters) {
        if (!_matchesFilter(employee, f.field, f.operator, f.value)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);

    return EmployeesListResult(
      status: result.status,
      success: result.success,
      total: result.total,
      employees: filtered,
    );
  },
);
