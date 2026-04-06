import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/vms_api_config.dart';
import '../models/visitor_record.dart';
import '../models/visitors_query_params.dart';

class VisitorsApiException implements Exception {
  VisitorsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'VisitorsApiException($statusCode): $message';
}

class VisitorsApiService {
  VisitorsApiService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kVmsHrBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl$kGetAllVisitorsPath');

  Future<VisitorsListResult> fetchVisitors({
    required VisitorsQueryParams params,
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
      throw VisitorsApiException(
        response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw VisitorsApiException('Invalid JSON root');
    }

    final status = decoded['Status']?.toString() ?? '';
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      return VisitorsListResult(status: status, visitors: const [], totalCount: 0);
    }

    final list = data['data'];
    final count = data['count'];
    final total = count is int ? count : int.tryParse('$count') ?? 0;

    if (list is! List) {
      return VisitorsListResult(status: status, visitors: const [], totalCount: total);
    }

    final visitors = list
        .whereType<Map<String, dynamic>>()
        .map(VisitorRecord.fromJson)
        .toList(growable: false);

    return VisitorsListResult(
      status: status,
      visitors: visitors,
      totalCount: total,
    );
  }

  void close() {
    _client.close();
  }
}
