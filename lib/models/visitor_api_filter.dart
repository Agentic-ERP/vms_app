import 'package:flutter/foundation.dart';

/// Single filter entry for [get-all-visitors] POST body.
@immutable
class VisitorApiFilter {
  const VisitorApiFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final String operator;
  final String value;

  Map<String, dynamic> toJson() => {
        'field': field,
        'operator': operator,
        'value': value,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitorApiFilter &&
          field == other.field &&
          operator == other.operator &&
          value == other.value;

  @override
  int get hashCode => Object.hash(field, operator, value);
}
