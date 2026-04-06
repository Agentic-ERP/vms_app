class AddVisitorPhotoResponse {
  const AddVisitorPhotoResponse({
    required this.status,
    required this.raw,
  });

  final String status;
  final Map<String, dynamic> raw;

  bool get isSuccess {
    final normalized = status.trim().toLowerCase();
    return normalized == 'success' || normalized.contains('success');
  }
}
