class VerifyVisitorLogOtpRequest {
  const VerifyVisitorLogOtpRequest({
    required this.visitId,
    required this.otp,
  });

  final String visitId;
  final String otp;

  Map<String, dynamic> toJson() => {
        'visit_id': visitId,
        'otp': otp,
      };
}

class VerifyVisitorLogOtpResponse {
  const VerifyVisitorLogOtpResponse({
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
