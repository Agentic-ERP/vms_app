import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor_api_filter.dart';
import '../models/visitor_record.dart';
import '../models/visitors_query_params.dart';
import '../providers/visitor_session_provider.dart';
import '../providers/visitors_api_service_provider.dart';
import '../services/visitors_api_service.dart';
import '../theme/app_theme.dart';

/// Right drawer: unit-scoped list + `search` (see get-all-visitors), with scroll pagination.
class VisitorApiPickerDrawer extends ConsumerStatefulWidget {
  const VisitorApiPickerDrawer({
    super.key,
    required this.unit,
    required this.onSelected,
  });

  /// HR unit id sent as `filter: [{ field: unit, operator: equals, value }]`.
  final String unit;

  final ValueChanged<VisitorRecord> onSelected;

  @override
  ConsumerState<VisitorApiPickerDrawer> createState() =>
      _VisitorApiPickerDrawerState();
}

class _VisitorApiPickerDrawerState extends ConsumerState<VisitorApiPickerDrawer> {
  static const int _pageLimit = 10;

  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _debouncedQuery = '';

  int _fetchGeneration = 0;

  final List<VisitorRecord> _items = [];
  int _totalCount = 0;
  int _lastPageSize = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadFromStart());
  }

  void _onSearchTextChanged() {
    final text = _searchCtrl.text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = text.trim());
      _reloadFromStart();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || _loadError != null) {
      return;
    }
    if (!_serverHasMore) return;

    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _fetchNextPage();
    }
  }

  bool get _serverHasMore {
    if (_totalCount > 0) return _items.length < _totalCount;
    return _lastPageSize >= _pageLimit;
  }

  VisitorsQueryParams _paramsForSkip(int skip) {
    final u = widget.unit.trim().isEmpty ? '1' : widget.unit.trim();
    final q = _debouncedQuery;
    return VisitorsQueryParams(
      skip: skip,
      limit: _pageLimit,
      filter: [
        VisitorApiFilter(
          field: 'unit',
          operator: 'equals',
          value: u,
        ),
      ],
      sort: const [],
      search: q.isEmpty ? null : q,
    );
  }

  Future<void> _reloadFromStart() async {
    final gen = ++_fetchGeneration;
    setState(() {
      _items.clear();
      _totalCount = 0;
      _lastPageSize = 0;
      _loadError = null;
      _loading = true;
      _loadingMore = false;
    });
    await _fetchNextPage(expectedGen: gen);
  }

  Future<void> _fetchNextPage({int? expectedGen}) async {
    final gen = expectedGen ?? _fetchGeneration;

    if (_loadingMore) return;
    if (!_loading && !_serverHasMore) return;

    final isInitial = _loading;
    if (!isInitial) {
      setState(() => _loadingMore = true);
    }

    try {
      final params = _paramsForSkip(_items.length);
      final service = ref.read(visitorsApiServiceProvider);
      final cookieHeader = ref.read(hrCookieHeaderProvider);
      final result = await service.fetchVisitors(
        params: params,
        cookieHeader: cookieHeader,
      );
      if (!mounted || gen != _fetchGeneration) return;
      if (!result.isSuccess) {
        throw VisitorsApiException('API Status: ${result.status}');
      }
      setState(() {
        _items.addAll(result.visitors);
        _totalCount = result.totalCount;
        _lastPageSize = result.visitors.length;
        _loading = false;
        _loadingMore = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted || gen != _fetchGeneration) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _loadError = e;
      });
    }
  }

  @override
  void didUpdateWidget(covariant VisitorApiPickerDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit != widget.unit) {
      _reloadFromStart();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchTextChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _visitorAvatar(BuildContext context, VisitorRecord v) {
    final url = (v.photoUrls != null && v.photoUrls!.isNotEmpty)
        ? v.photoUrls!.first
        : null;

    Widget fallback(BuildContext context) => CircleAvatar(
          radius: 20,
          backgroundColor: VmsColors.fieldFill,
          child: Icon(
            Icons.person_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );

    if (url == null || url.isEmpty) {
      return fallback(context);
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (40 * dpr).round();

    return ClipOval(
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        cacheWidth: px,
        cacheHeight: px,
        errorBuilder: (_, __, ___) => fallback(context),
      ),
    );
  }

  Widget _buildListBody(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_loadError',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _reloadFromStart,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No visitors',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    final hasMore = _serverHasMore;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${_items.length} shown · $_totalCount total',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _items.length + (hasMore && _loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final v = _items[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0)
                        const Divider(height: 1, color: VmsColors.border),
                      ListTile(
                        key: ValueKey<String>(v.visitorId),
                        leading: _visitorAvatar(context, v),
                        title: Text(
                          v.fullName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${v.phoneNumber} · ${v.companyName}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => widget.onSelected(v),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        if (_loadingMore && _items.isNotEmpty)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          title: const Text('Select visitor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Scaffold.of(context).closeEndDrawer(),
            ),
          ],
        ),
        const Divider(height: 1, color: VmsColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              isDense: true,
              filled: true,
              fillColor: VmsColors.fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: VmsColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: VmsColors.border),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildListBody(context),
        ),
      ],
    );
  }
}
