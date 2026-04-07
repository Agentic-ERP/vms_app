import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unit_option.dart';
import '../providers/selected_unit_provider.dart';
import '../widgets/line_o_matic_logo.dart';
import '../widgets/unit_select_tile.dart';

class UnitSelectionScreen extends ConsumerWidget {
  const UnitSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LineOMaticLogo(height: 44),
              const SizedBox(height: 32),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final landscape = MediaQuery.orientationOf(context) ==
                        Orientation.landscape;

                    if (landscape) {
                      final rowHeight = (constraints.maxHeight * 0.4)
                          .clamp(72.0, 120.0);
                      return Center(
                        child: SizedBox(
                          height: rowHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < UnitOption.all.length; i++) ...[
                                if (i > 0) const SizedBox(width: 12),
                                Expanded(
                                  child: UnitSelectTile(
                                    label: UnitOption.all[i].label,
                                    onTap: () => ref
                                        .read(selectedUnitProvider.notifier)
                                        .setUnit(UnitOption.all[i].id),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.4,
                        children: [
                          for (final unit in UnitOption.all)
                            UnitSelectTile(
                              label: unit.label,
                              onTap: () => ref
                                  .read(selectedUnitProvider.notifier)
                                  .setUnit(unit.id),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
