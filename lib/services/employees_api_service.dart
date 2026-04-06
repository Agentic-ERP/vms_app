import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/vms_api_config.dart';
import '../models/employee_record.dart';
import '../models/employees_query_params.dart';

class EmployeesApiException implements Exception {
  EmployeesApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'EmployeesApiException($statusCode): $message';
}

class EmployeesApiService {
  EmployeesApiService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kVmsHrBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl$kGetEmployeesByUnitFromLogsPath');

  Future<EmployeesListResult> fetchEmployees({
    required EmployeesQueryParams params,
    String? cookieHeader,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }

    final response = await _client.post(
      _uri,
      headers: headers,
      body: jsonEncode(params.toRequestBody()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EmployeesApiException(
        response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw EmployeesApiException('Invalid JSON root');
    }

    final status = decoded['Status']?.toString() ?? '';
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      return EmployeesListResult(
        status: status,
        success: false,
        total: 0,
        employees: const [],
      );
    }

    final success = data['success'] == true;
    final totalRaw = data['total'];
    final total = totalRaw is int ? totalRaw : int.tryParse('$totalRaw') ?? 0;
    final list = data['data'];
    if (list is! List) {
      return EmployeesListResult(
        status: status,
        success: success,
        total: total,
        employees: const [],
      );
    }

    final employees = list
        .whereType<Map<String, dynamic>>()
        .map(EmployeeRecord.fromJson)
        .toList(growable: false);

    return EmployeesListResult(
      status: status,
      success: success,
      total: total,
      employees: employees,
    );
  }

  void close() {
    _client.close();
  }
}
