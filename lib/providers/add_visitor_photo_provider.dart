import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/add_visitor_photo_response.dart';
import '../services/add_visitor_photo_service.dart';
import 'visitor_session_provider.dart';

final addVisitorPhotoServiceProvider = Provider<AddVisitorPhotoService>((ref) {
  final service = AddVisitorPhotoService();
  ref.onDispose(service.close);
  return service;
});

class AddVisitorPhotoController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<AddVisitorPhotoResponse> submit({
    required String visitorId,
    required Uint8List photoBytes,
    required String filename,
  }) async {
    state = const AsyncLoading();
    final service = ref.read(addVisitorPhotoServiceProvider);
    final cookieHeader = ref.read(hrCookieHeaderProvider);

    final result = await AsyncValue.guard(
      () => service.uploadPhoto(
        visitorId: visitorId,
        photoBytes: photoBytes,
        filename: filename,
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

final addVisitorPhotoControllerProvider =
    AutoDisposeAsyncNotifierProvider<AddVisitorPhotoController, void>(
  AddVisitorPhotoController.new,
);
