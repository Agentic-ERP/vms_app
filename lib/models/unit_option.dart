/// Static list of selectable units (1–4).
class UnitOption {
  const UnitOption(this.id);

  final int id;

  String get label => 'Unit $id';

  static const List<UnitOption> all = [
    UnitOption(1),
    UnitOption(2),
    UnitOption(3),
    UnitOption(4),
  ];
}
