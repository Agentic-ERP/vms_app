import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/verify_visitor_log_otp_request.dart';
import '../services/verify_visitor_log_otp_service.dart';
import 'visitor_session_provider.dart';

final verifyVisitorLogOtpServiceProvider = Provider<VerifyVisitorLogOtpService>((ref) {
  final service = VerifyVisitorLogOtpService();
  ref.onDispose(service.close);
  return service;
});

class VerifyVisitorLogOtpController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<VerifyVisitorLogOtpResponse> submit(VerifyVisitorLogOtpRequest request) async {
    state = const AsyncLoading();
    final service = ref.read(verifyVisitorLogOtpServiceProvider);
    final cookieHeader = ref.read(hrCookieHeaderProvider);

    final result = await AsyncValue.guard(
      () => service.submit(
        request: request,
        cookieHeader: cookieHeader,
      ),
    );
    state = result.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );
    if (result.hasError) throw result.error!;
    return result.value!;
  }
}

final verifyVisitorLogOtpControllerProvider =
    AutoDisposeAsyncNotifierProvider<VerifyVisitorLogOtpController, void>(
  VerifyVisitorLogOtpController.new,
);
