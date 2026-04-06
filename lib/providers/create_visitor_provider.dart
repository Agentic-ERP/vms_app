import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/create_visitor_request.dart';
import '../services/create_visitor_service.dart';
import 'visitor_session_provider.dart';

final createVisitorServiceProvider = Provider<CreateVisitorService>((ref) {
  final service = CreateVisitorService();
  ref.onDispose(service.close);
  return service;
});

class CreateVisitorController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CreateVisitorResponse> submit(CreateVisitorRequest request) async {
    state = const AsyncLoading();
    final service = ref.read(createVisitorServiceProvider);
    final cookieHeader = ref.read(hrCookieHeaderProvider);

    final result = await AsyncValue.guard(
      () => service.createVisitor(
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

final createVisitorControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreateVisitorController, void>(
  CreateVisitorController.new,
);
