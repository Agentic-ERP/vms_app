import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/visitors_api_service.dart';

final visitorsApiServiceProvider = Provider<VisitorsApiService>((ref) {
  final service = VisitorsApiService();
  ref.onDispose(service.close);
  return service;
});
