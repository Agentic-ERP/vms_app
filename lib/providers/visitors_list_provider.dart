import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitors_query_params.dart';
import '../models/visitor_record.dart';
import '../services/visitors_api_service.dart';
import 'visitor_session_provider.dart';
import 'visitors_api_service_provider.dart';

/// Fetches visitors for the given [VisitorsQueryParams] (skip, limit, filter, sort).
final visitorsListProvider =
    FutureProvider.autoDispose.family<VisitorsListResult, VisitorsQueryParams>(
  (ref, params) async {
    final service = ref.watch(visitorsApiServiceProvider);
    final cookieHeader = ref.watch(hrCookieHeaderProvider);
    final result = await service.fetchVisitors(
      params: params,
      cookieHeader: cookieHeader,
    );
    if (!result.isSuccess) {
      throw VisitorsApiException('API Status: ${result.status}');
    }
    return result;
  },
);
