import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'visitor_api_filter.dart';

/// Request parameters for [get-all-visitors].
///
/// Use with [visitorsListProvider] family.
@immutable
class VisitorsQueryParams {
  const VisitorsQueryParams({
    this.skip = 0,
    this.limit = 10,
    this.filter = const [],
    this.sort = const [],
  });

  final int skip;
  final int limit;
  final List<VisitorApiFilter> filter;

  /// Opaque sort clauses as sent to the API (shape depends on backend).
  final List<Map<String, dynamic>> sort;

  Map<String, dynamic> toRequestBody() => {
        'skip': skip,
        'limit': limit,
        'filter': filter.map((f) => f.toJson()).toList(),
        'sort': sort,
      };

  VisitorsQueryParams copyWith({
    int? skip,
    int? limit,
    List<VisitorApiFilter>? filter,
    List<Map<String, dynamic>>? sort,
  }) {
    return VisitorsQueryParams(
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  static const _listEq = ListEquality<VisitorApiFilter>();
  static const _sortEq = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitorsQueryParams &&
          skip == other.skip &&
          limit == other.limit &&
          _listEq.equals(filter, other.filter) &&
          _sortEq.equals(sort, other.sort);

  @override
  int get hashCode => Object.hash(
        skip,
        limit,
        _listEq.hash(filter),
        _sortEq.hash(sort),
      );
}
