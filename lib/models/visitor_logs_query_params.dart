import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'visitor_api_filter.dart';

@immutable
class VisitorLogsQueryParams {
  const VisitorLogsQueryParams({
    this.skip = 0,
    this.limit = 10,
    this.filter = const [],
    this.sort = const [],
    this.search = '',
  });

  final int skip;
  final int limit;
  final List<VisitorApiFilter> filter;
  final List<Map<String, dynamic>> sort;
  final String search;

  Map<String, dynamic> toRequestBody() => {
        'skip': skip,
        'limit': limit,
        'filter': filter.map((f) => f.toJson()).toList(),
        'sort': sort,
        'search': search,
      };

  VisitorLogsQueryParams copyWith({
    int? skip,
    int? limit,
    List<VisitorApiFilter>? filter,
    List<Map<String, dynamic>>? sort,
    String? search,
  }) {
    return VisitorLogsQueryParams(
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      search: search ?? this.search,
    );
  }

  static const _filterEq = ListEquality<VisitorApiFilter>();
  static const _sortEq = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitorLogsQueryParams &&
          skip == other.skip &&
          limit == other.limit &&
          search == other.search &&
          _filterEq.equals(filter, other.filter) &&
          _sortEq.equals(sort, other.sort);

  @override
  int get hashCode => Object.hash(
        skip,
        limit,
        search,
        _filterEq.hash(filter),
        _sortEq.hash(sort),
      );
}
