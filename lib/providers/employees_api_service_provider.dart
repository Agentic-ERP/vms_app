import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/employees_api_service.dart';

final employeesApiServiceProvider = Provider<EmployeesApiService>((ref) {
  final service = EmployeesApiService();
  ref.onDispose(service.close);
  return service;
});
