import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/create_visitor_log_request.dart';
import '../services/create_visitor_log_service.dart';
import 'visitor_session_provider.dart';

final createVisitorLogServiceProvider = Provider<CreateVisitorLogService>((ref) {
  final service = CreateVisitorLogService();
  ref.onDispose(service.close);
  return service;
});

class CreateVisitorLogController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CreateVisitorLogResponse> submit(CreateVisitorLogRequest request) async {
    state = const AsyncLoading();
    final service = ref.read(createVisitorLogServiceProvider);
    final cookieHeader = ref.read(hrCookieHeaderProvider);

    final result = await AsyncValue.guard(
      () => service.createVisitorLog(
        request: request,
        cookieHeader: cookieHeader,
      ),
    );
    state = result.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );
    if (result.hasError) {
      throw result.error!;
    }
    return result.value!;
  }
}

final createVisitorLogControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreateVisitorLogController, void>(
  CreateVisitorLogController.new,
);
