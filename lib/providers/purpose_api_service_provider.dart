import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purpose_api_service.dart';

final purposeApiServiceProvider = Provider<PurposeApiService>((ref) {
  final service = PurposeApiService();
  ref.onDispose(service.close);
  return service;
});
