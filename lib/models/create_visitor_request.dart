class CreateVisitorRequest {
  const CreateVisitorRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.companyName,
    required this.faceEmbeddings,
  });

  final String fullName;
  final String phoneNumber;
  final String companyName;
  final List<double> faceEmbeddings;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'company_name': companyName,
        'face_embeddings': faceEmbeddings,
      };
}

class CreateVisitorResponse {
  const CreateVisitorResponse({
    required this.status,
    required this.raw,
  });

  final String status;
  final Map<String, dynamic> raw;

  bool get isSuccess {
    final normalized = status.trim().toLowerCase();
    return normalized == 'success' || normalized.contains('success');
  }

  /// Tries to read visitor id from common backend response shapes.
  String? get createdVisitorId {
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      final directVisitorId = data['visitor_id'];
      if (directVisitorId != null && '$directVisitorId'.isNotEmpty) {
        return '$directVisitorId';
      }
      final directId = data['id'];
      if (directId != null && '$directId'.isNotEmpty) {
        return '$directId';
      }
      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic>) {
        final nestedVisitorId = nestedData['visitor_id'];
        if (nestedVisitorId != null && '$nestedVisitorId'.isNotEmpty) {
          return '$nestedVisitorId';
        }
        final nestedId = nestedData['id'];
        if (nestedId != null && '$nestedId'.isNotEmpty) {
          return '$nestedId';
        }
      }
    }

    final rootVisitorId = raw['visitor_id'];
    if (rootVisitorId != null && '$rootVisitorId'.isNotEmpty) {
      return '$rootVisitorId';
    }
    return null;
  }
}
