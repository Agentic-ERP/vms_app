import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/vms_api_config.dart';
import '../models/create_visitor_request.dart';

class CreateVisitorException implements Exception {
  CreateVisitorException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CreateVisitorException($statusCode): $message';
}

class CreateVisitorService {
  CreateVisitorService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kVmsHrBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl$kCreateVisitorPath');

  Future<CreateVisitorResponse> createVisitor({
    required CreateVisitorRequest request,
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
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CreateVisitorException(
        response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw CreateVisitorException('Invalid JSON root');
    }

    return CreateVisitorResponse(
      status: decoded['Status']?.toString() ?? '',
      raw: decoded,
    );
  }

  void close() {
    _client.close();
  }
}
