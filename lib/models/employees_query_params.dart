import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'employee_api_filter.dart';

/// Request params for get-employees-by-unit-from-logs.
@immutable
class EmployeesQueryParams {
  const EmployeesQueryParams({
    required this.unit,
    required this.date,
    this.skip = 0,
    this.limit = 10,
    this.sort = const [],
    this.localFilters = const [],
  });

  final String unit;
  final String date;
  final int skip;
  final int limit;
  final List<Map<String, dynamic>> sort;
  final List<EmployeeApiFilter> localFilters;

  Map<String, dynamic> toRequestBody() => {
        'unit': unit,
        'date': date,
        'skip': skip,
        'limit': limit,
        'sort': sort,
      };

  EmployeesQueryParams copyWith({
    String? unit,
    String? date,
    int? skip,
    int? limit,
    List<Map<String, dynamic>>? sort,
    List<EmployeeApiFilter>? localFilters,
  }) {
    return EmployeesQueryParams(
      unit: unit ?? this.unit,
      date: date ?? this.date,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      sort: sort ?? this.sort,
      localFilters: localFilters ?? this.localFilters,
    );
  }

  static const _sortEq = DeepCollectionEquality();
  static const _filterEq = ListEquality<EmployeeApiFilter>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeesQueryParams &&
          unit == other.unit &&
          date == other.date &&
          skip == other.skip &&
          limit == other.limit &&
          _sortEq.equals(sort, other.sort) &&
          _filterEq.equals(localFilters, other.localFilters);

  @override
  int get hashCode => Object.hash(
        unit,
        date,
        skip,
        limit,
        _sortEq.hash(sort),
        _filterEq.hash(localFilters),
      );
}
