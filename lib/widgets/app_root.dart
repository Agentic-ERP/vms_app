import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/selected_unit_provider.dart';
import '../screens/create_visitor_entry_screen.dart';
import '../screens/unit_selection_screen.dart';

/// Unit selection when none saved; otherwise the visitor entry form.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(selectedUnitProvider);

    return unitAsync.when(
      data: (unitId) => unitId == null
          ? const UnitSelectionScreen()
          : const CreateVisitorEntryScreen(),
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
