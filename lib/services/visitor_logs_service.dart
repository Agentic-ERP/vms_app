import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/vms_api_config.dart';
import '../models/visitor_log_record.dart';
import '../models/visitor_logs_query_params.dart';

class VisitorLogsException implements Exception {
  VisitorLogsException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'VisitorLogsException($statusCode): $message';
}

class VisitorLogsService {
  VisitorLogsService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kVmsHrBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl$kGetAllVisitorLogsByEmployeeIdPath');

  Future<VisitorLogsListResult> fetchLogs({
    required VisitorLogsQueryParams params,
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
      throw VisitorLogsException(
        response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw VisitorLogsException('Invalid JSON root');
    }
    final status = decoded['Status']?.toString() ?? '';
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      return VisitorLogsListResult(status: status, logs: const [], totalCount: 0);
    }

    final rawList = data['data'];
    final countRaw = data['count'];
    final totalCount = countRaw is int ? countRaw : int.tryParse('$countRaw') ?? 0;
    if (rawList is! List) {
      return VisitorLogsListResult(
        status: status,
        logs: const [],
        totalCount: totalCount,
      );
    }

    final logs = rawList
        .whereType<Map<String, dynamic>>()
        .map(VisitorLogRecord.fromJson)
        .toList(growable: false);

    return VisitorLogsListResult(
      status: status,
      logs: logs,
      totalCount: totalCount,
    );
  }

  void close() {
    _client.close();
  }
}
