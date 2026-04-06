import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'selected_unit_id';

class SelectedUnit extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_prefsKey);
    if (raw == null || raw < 1 || raw > 4) return null;
    return raw;
  }

  Future<void> setUnit(int unitId) async {
    if (unitId < 1 || unitId > 4) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, unitId);
    state = AsyncValue.data(unitId);
  }

  Future<void> clearUnit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    state = const AsyncValue.data(null);
  }
}

final selectedUnitProvider =
    AsyncNotifierProvider<SelectedUnit, int?>(SelectedUnit.new);
