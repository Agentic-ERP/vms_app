import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/selected_unit_provider.dart';
import '../screens/check_mode_selection_screen.dart';
import '../screens/unit_selection_screen.dart';

/// Unit selection when none saved; otherwise check-in/out choice.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(selectedUnitProvider);

    return unitAsync.when(
      data: (unitId) => unitId == null
          ? const UnitSelectionScreen()
          : const CheckModeSelectionScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load saved unit.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
