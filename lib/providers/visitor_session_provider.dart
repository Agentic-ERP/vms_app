import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `visitor_id` cookie value for HR API calls.
///
/// Replace via [StateController] after login, or override in tests.
final visitorSessionIdProvider = StateProvider<String?>((ref) {
  // Dev default from your curl; clear or set after real auth.
  return '7faab71d-2647-43b7-a359-d30420e959d9';
});

/// `session_id` cookie used by employee attendance API.
final sessionIdProvider = StateProvider<String?>((ref) {
  // Dev default from your curl; clear or set after real auth.
  return '326304a8-1c39-494f-b9a2-61b1b52e3f83';
});

/// Combined Cookie header used by HR APIs.
final hrCookieHeaderProvider = Provider<String?>((ref) {
  final visitorId = ref.watch(visitorSessionIdProvider);
  final sessionId = ref.watch(sessionIdProvider);
  final parts = <String>[
    if (visitorId != null && visitorId.isNotEmpty) 'visitor_id=$visitorId',
    if (sessionId != null && sessionId.isNotEmpty) 'session_id=$sessionId',
  ];
  if (parts.isEmpty) return null;
  return parts.join('; ');
});
