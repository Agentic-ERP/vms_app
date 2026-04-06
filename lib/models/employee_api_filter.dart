import 'package:flutter/foundation.dart';

/// Local filter entry applied client-side to fetched employee rows.
@immutable
class EmployeeApiFilter {
  const EmployeeApiFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final String operator;
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeApiFilter &&
          field == other.field &&
          operator == other.operator &&
          value == other.value;

  @override
  int get hashCode => Object.hash(field, operator, value);
}
