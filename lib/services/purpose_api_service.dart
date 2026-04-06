import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/vms_api_config.dart';
import '../models/purpose_query_params.dart';
import '../models/purpose_reason.dart';

class PurposeApiException implements Exception {
  PurposeApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'PurposeApiException($statusCode): $message';
}

class PurposeApiService {
  PurposeApiService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kVmsHrBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl$kPurposeMasterListPath');

  Future<PurposeReasonListResult> fetchReasons({
    required PurposeQueryParams params,
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
      throw PurposeApiException(
        response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw PurposeApiException('Invalid JSON root');
    }
    final status = decoded['Status']?.toString() ?? '';
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      return PurposeReasonListResult(status: status, total: 0, reasons: const []);
    }

    final totalRaw = data['total'];
    final total = totalRaw is int ? totalRaw : int.tryParse('$totalRaw') ?? 0;
    final list = data['data'];
    if (list is! List) {
      return PurposeReasonListResult(status: status, total: total, reasons: const []);
    }

    final reasons = list
        .whereType<Map<String, dynamic>>()
        .map(PurposeReason.fromJson)
        .toList(growable: false);

    return PurposeReasonListResult(
      status: status,
      total: total,
      reasons: reasons,
    );
  }

  void close() {
    _client.close();
  }
}
