class PurposeReason {
  const PurposeReason({
    required this.id,
    required this.reason,
    required this.status,
  });

  final int id;
  final String reason;
  final String status;

  factory PurposeReason.fromJson(Map<String, dynamic> json) {
    return PurposeReason(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class PurposeReasonListResult {
  const PurposeReasonListResult({
    required this.status,
    required this.total,
    required this.reasons,
  });

  final String status;
  final int total;
  final List<PurposeReason> reasons;

  bool get isSuccess => status == 'Success';
}
