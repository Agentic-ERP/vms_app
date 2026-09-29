import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/vms_api_config.dart';
import '../models/gate_inward_file.dart';
import '../models/gate_inward_sse_event.dart';

MediaType _contentTypeFor(String filename) {
  return filename.toLowerCase().endsWith('.pdf')
      ? MediaType('application', 'pdf')
      : MediaType('image', 'jpeg');
}

class AutomateGateInwardException implements Exception {
  AutomateGateInwardException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AutomateGateInwardException($statusCode): $message';
}

class AutomateGateInwardService {
  AutomateGateInwardService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kGateInwardApiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl$kAutomateGateInwardPath');

  /// Uploads the gate documents (each slot may hold more than one file,
  /// e.g. a multi-page LR receipt — every file is sent under that slot's
  /// field name, so the backend receives it as an array) and streams back
  /// the OCR/verification pipeline's progress as Server-Sent Events (one
  /// [GateInwardSseEvent] per `event:`/`data:` frame), ending with the
  /// `completed` step or an `error` frame.
  Stream<GateInwardSseEvent> process({
    required List<GateInwardFile> ewayBillFiles,
    required List<GateInwardFile> invoiceFiles,
    required List<GateInwardFile> lrReceiptFiles,
  }) async* {
    final req = http.MultipartRequest('POST', _uri)
      ..headers['Accept'] = 'text/event-stream'
      // Skips ngrok's free-tier HTML interstitial warning page so the
      // actual SSE response comes straight through.
      ..headers['ngrok-skip-browser-warning'] = 'true';

    void addFiles(String field, List<GateInwardFile> files) {
      for (final f in files) {
        req.files.add(http.MultipartFile.fromBytes(
          field,
          f.bytes,
          filename: f.filename,
          contentType: _contentTypeFor(f.filename),
        ));
      }
    }

    addFiles('eway_bill_document', ewayBillFiles);
    addFiles('einvoice_document', invoiceFiles);
    addFiles('lr_receipt_document', lrReceiptFiles);

    final streamed = await _client.send(req);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final body = await streamed.stream.bytesToString();
      throw AutomateGateInwardException(
        body.isNotEmpty ? body : 'HTTP ${streamed.statusCode}',
        statusCode: streamed.statusCode,
      );
    }

    // This backend sometimes emits several `data:` lines under one
    // `event:` header with no blank line between them (e.g. two
    // `document_extracted` messages, or a final `error` immediately
    // followed by `completed`). Each `data:` line is always a complete,
    // standalone JSON object here, so every one is decoded and yielded as
    // its own event rather than being concatenated into a single buffer.
    String? currentEventType;

    final lines = streamed.stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (line.startsWith(':')) {
        continue; // SSE comment / keep-alive ping — ignore.
      }
      if (line.isEmpty) {
        currentEventType = null;
        continue;
      }
      if (line.startsWith('event:')) {
        currentEventType = line.substring('event:'.length).trim();
      } else if (line.startsWith('data:')) {
        final dataStr = line.substring('data:'.length).trim();
        if (dataStr.isNotEmpty) {
          final decoded = jsonDecode(dataStr);
          if (decoded is Map<String, dynamic>) {
            yield GateInwardSseEvent(
              sseType: currentEventType ?? 'message',
              raw: decoded,
            );
          }
        }
      }
    }
  }

  void close() {
    _client.close();
  }
}
