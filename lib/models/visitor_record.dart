/// One visitor row from get-all-visitors `data.data`.
class VisitorRecord {
  const VisitorRecord({
    required this.visitorId,
    required this.fullName,
    required this.phoneNumber,
    required this.companyName,
    this.faceEmbeddings,
    this.createdAt,
    this.photoUrls,
    this.isBlackListed = false,
  });

  final String visitorId;
  final String fullName;
  final String phoneNumber;
  final String companyName;
  final List<double>? faceEmbeddings;
  final DateTime? createdAt;
  final List<String>? photoUrls;
  final bool isBlackListed;

  factory VisitorRecord.fromJson(Map<String, dynamic> json) {
    List<double>? embeddings;
    final fe = json['face_embeddings'];
    if (fe is List) {
      embeddings = fe
          .map((e) => (e as num).toDouble())
          .toList(growable: false);
    }

    List<String>? photos;
    final ph = json['photo'];
    if (ph is List) {
      photos = ph.map((e) => e.toString()).toList(growable: false);
    }

    DateTime? created;
    final ca = json['created_at'];
    if (ca is String) {
      created = DateTime.tryParse(ca);
    }

    return VisitorRecord(
      visitorId: json['visitor_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      faceEmbeddings: embeddings,
      createdAt: created,
      photoUrls: photos,
      isBlackListed: json['is_black_listed'] == true,
    );
  }
}

/// Parsed API envelope for get-all-visitors.
class VisitorsListResult {
  const VisitorsListResult({
    required this.status,
    required this.visitors,
    required this.totalCount,
  });

  final String status;
  final List<VisitorRecord> visitors;
  final int totalCount;

  bool get isSuccess => status == 'Success';
}
