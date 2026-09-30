import 'dart:typed_data';

class CreateVisitorRequest {
  const CreateVisitorRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.photoBytes,
    required this.photoFilename,
    this.companyName,
    this.faceEmbeddings,
    this.isBlackListed,
  });

  final String fullName;
  final String phoneNumber;
  final String? companyName;
  final List<double>? faceEmbeddings;
  final Uint8List photoBytes;
  final String photoFilename;
  final bool? isBlackListed;
}

class CreateVisitorResponse {
  const CreateVisitorResponse({
    required this.message,
    required this.raw,
    this.status,
    this.visitorId,
    this.photoUrls,
  });

  final String message;
  final Map<String, dynamic> raw;
  final String? status;
  final String? visitorId;
  final List<String>? photoUrls;

  bool get isSuccess {
    final statusNorm = (status ?? '').trim().toLowerCase();
    if (statusNorm == 'success' || statusNorm.contains('success')) {
      return true;
    }
    final messageNorm = message.trim().toLowerCase();
    return messageNorm.contains('success') || visitorId != null;
  }

  String? get createdVisitorId => visitorId;

  factory CreateVisitorResponse.fromJson(Map<String, dynamic> json) {
    final status = json['Status']?.toString() ?? json['status']?.toString();

    final topData = json['data'];
    final envelope = topData is Map<String, dynamic> ? topData : null;

    var message = json['message']?.toString() ?? json['Message']?.toString() ?? '';
    if (message.isEmpty && envelope != null) {
      message = envelope['message']?.toString() ?? '';
    }

    Map<String, dynamic>? payload = envelope;
    if (envelope != null && envelope['visitor_id'] == null) {
      final nested = envelope['data'];
      if (nested is Map<String, dynamic>) {
        payload = nested;
      }
    }

    String? visitorId;
    List<String>? photos;
    if (payload != null) {
      final id = payload['visitor_id'];
      if (id != null && '$id'.isNotEmpty) {
        visitorId = '$id';
      }
      final rawPhotos = payload['photo'];
      if (rawPhotos is List) {
        photos = rawPhotos.map((e) => e.toString()).toList(growable: false);
      }
    }

    return CreateVisitorResponse(
      status: status,
      message: message,
      raw: json,
      visitorId: visitorId,
      photoUrls: photos,
    );
  }
}
