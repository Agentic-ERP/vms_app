import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/vms_api_config.dart';
import '../models/add_visitor_photo_response.dart';

class AddVisitorPhotoException implements Exception {
  AddVisitorPhotoException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AddVisitorPhotoException($statusCode): $message';
}

class AddVisitorPhotoService {
  AddVisitorPhotoService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kVmsHrBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl$kAddVisitorPhotoPath');

  Future<AddVisitorPhotoResponse> uploadPhoto({
    required String visitorId,
    required Uint8List photoBytes,
    required String filename,
    String? cookieHeader,
  }) async {
    final req = http.MultipartRequest('POST', _uri);
    req.headers['Accept'] = 'application/json';
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      req.headers['Cookie'] = cookieHeader;
    }
    req.fields['visitor_id'] = visitorId;
    req.files.add(
      http.MultipartFile.fromBytes(
        'visitor_photo',
        photoBytes,
        filename: filename,
      ),
    );

    final streamed = await _client.send(req);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw AddVisitorPhotoException(
        body.isNotEmpty ? body : 'HTTP ${streamed.statusCode}',
        statusCode: streamed.statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw AddVisitorPhotoException('Invalid JSON root');
    }
    return AddVisitorPhotoResponse(
      status: decoded['Status']?.toString() ?? '',
      raw: decoded,
    );
  }

  void close() {
    _client.close();
  }
}
