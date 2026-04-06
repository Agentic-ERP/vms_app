import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/purpose_query_params.dart';
import '../models/purpose_reason.dart';
import '../services/purpose_api_service.dart';
import 'purpose_api_service_provider.dart';
import 'visitor_session_provider.dart';

final purposeReasonsProvider = FutureProvider.autoDispose
    .family<PurposeReasonListResult, PurposeQueryParams>((ref, params) async {
  final service = ref.watch(purposeApiServiceProvider);
  final cookieHeader = ref.watch(hrCookieHeaderProvider);

  final result = await service.fetchReasons(
    params: params,
    cookieHeader: cookieHeader,
  );
  if (!result.isSuccess) {
    throw PurposeApiException('API Status: ${result.status}');
  }
  return result;
});
