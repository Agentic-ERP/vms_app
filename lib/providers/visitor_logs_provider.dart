import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor_log_record.dart';
import '../models/visitor_logs_query_params.dart';
import '../services/visitor_logs_service.dart';
import 'visitor_session_provider.dart';

final visitorLogsServiceProvider = Provider<VisitorLogsService>((ref) {
  final service = VisitorLogsService();
  ref.onDispose(service.close);
  return service;
});

final visitorLogsProvider =
    FutureProvider.autoDispose.family<VisitorLogsListResult, VisitorLogsQueryParams>(
  (ref, params) async {
    final service = ref.watch(visitorLogsServiceProvider);
    final cookieHeader = ref.watch(hrCookieHeaderProvider);
    final result = await service.fetchLogs(
      params: params,
      cookieHeader: cookieHeader,
    );
    if (!result.isSuccess) {
      throw VisitorLogsException('API Status: ${result.status}');
    }
    return result;
  },
);
