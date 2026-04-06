import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'visitor_api_filter.dart';

@immutable
class PurposeQueryParams {
  const PurposeQueryParams({
    this.skip = 0,
    this.limit = 10,
    this.filter = const [],
    this.sort = const [],
  });

  final int skip;
  final int limit;
  final List<VisitorApiFilter> filter;
  final List<Map<String, dynamic>> sort;

  Map<String, dynamic> toRequestBody() => {
        'filter': filter.map((f) => f.toJson()).toList(),
        'skip': skip,
        'limit': limit,
        'sort': sort,
      };

  static const _filterEq = ListEquality<VisitorApiFilter>();
  static const _sortEq = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurposeQueryParams &&
          skip == other.skip &&
          limit == other.limit &&
          _filterEq.equals(filter, other.filter) &&
          _sortEq.equals(sort, other.sort);

  @override
  int get hashCode =>
      Object.hash(skip, limit, _filterEq.hash(filter), _sortEq.hash(sort));
}
