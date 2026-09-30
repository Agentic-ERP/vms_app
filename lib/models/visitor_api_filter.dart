import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// Single filter entry for HR visitor POST bodies (`filter` array).
///
/// [value] is JSON-encoded as-is: a [String], [List] (e.g. `is in`, `date between`), etc.
@immutable
class VisitorApiFilter {
  const VisitorApiFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final String operator;
  final Object? value;

  Map<String, dynamic> toJson() => {
        'field': field,
        'operator': operator,
        'value': value,
      };

  static const _valEq = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitorApiFilter &&
          field == other.field &&
          operator == other.operator &&
          _valEq.equals(value, other.value);

  @override
  int get hashCode => Object.hash(field, operator, _valEq.hash(value));
}
