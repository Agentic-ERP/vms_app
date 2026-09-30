import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/vms_api_config.dart';
import '../models/create_visitor_request.dart';

class CreateVisitorException implements Exception {
  CreateVisitorException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CreateVisitorService {
  CreateVisitorService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kVmsHrBaseUrl;

  static const Duration _timeout = Duration(seconds: 120);

  final http.Client _client;
  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl$kCreateVisitorWithPhotoPath');

  Future<CreateVisitorResponse> createVisitor({
    required CreateVisitorRequest request,
    String? cookieHeader,
  }) async {
    final req = http.MultipartRequest('POST', _uri);
    req.headers['Accept'] = 'application/json';
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      req.headers['Cookie'] = cookieHeader;
    }

    req.fields['full_name'] = request.fullName;
    req.fields['phone_number'] = request.phoneNumber;
    final company = request.companyName?.trim();
    if (company != null && company.isNotEmpty) {
      req.fields['company_name'] = company;
    }
    if (request.faceEmbeddings != null) {
      req.fields['face_embeddings'] = jsonEncode(request.faceEmbeddings);
    }
    if (request.isBlackListed != null) {
      req.fields['is_black_listed'] = request.isBlackListed! ? 'true' : 'false';
    }

    req.files.add(
      http.MultipartFile.fromBytes(
        'visitor_photo',
        request.photoBytes,
        filename: request.photoFilename,
      ),
    );

    final streamed = await _client.send(req).timeout(
      _timeout,
      onTimeout: () {
        throw CreateVisitorException(
          'Failed to create visitor. Please try again.',
        );
      },
    );
    final body = await streamed.stream.bytesToString();
    final statusCode = streamed.statusCode;

    if (statusCode == 500) {
      throw CreateVisitorException(
        'Failed to create visitor. Please try again.',
        statusCode: statusCode,
      );
    }
    if (statusCode < 200 || statusCode >= 300) {
      throw CreateVisitorException(
        _messageFromBody(
          body,
          fallback: statusCode == 400
              ? 'Please check the form and try again.'
              : 'Failed to create visitor. Please try again.',
        ),
        statusCode: statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw CreateVisitorException('Invalid JSON root');
    }

    return CreateVisitorResponse.fromJson(decoded);
  }

  String _messageFromBody(String body, {required String fallback}) {
    if (body.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'] ??
            decoded['Message'] ??
            decoded['error'] ??
            decoded['Status'];
        if (message != null && '$message'.trim().isNotEmpty) {
          return '$message';
        }
      }
    } on FormatException {
      // Use raw body below.
    }
    return body;
  }

  void close() {
    _client.close();
  }
}
