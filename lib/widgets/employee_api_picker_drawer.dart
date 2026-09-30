import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_api_filter.dart';
import '../models/employee_record.dart';
import '../models/employees_query_params.dart';
import '../providers/visitor_session_provider.dart';
import '../providers/employees_api_service_provider.dart';
import '../services/employees_api_service.dart';
import '../theme/app_theme.dart';

bool _matchesFilter(EmployeeRecord e, EmployeeApiFilter f) {
  final needle = f.value.trim().toLowerCase();
  if (needle.isEmpty) return true;

  final String haystack;
  switch (f.field) {
    case 'full_name':
      haystack = e.fullName;
    case 'emp_code':
      haystack = e.empCode;
    case 'department_name':
      haystack = e.departmentName ?? '';
    case 'designation_name':
      haystack = e.designationName ?? '';
    default:
      return true;
  }

  final source = haystack.toLowerCase();
  switch (f.operator) {
    case 'equals':
      return source == needle;
    case 'contains':
    default:
      return source.contains(needle);
  }
}

List<EmployeeApiFilter> _localFiltersForQuery(String q) {
  if (q.isEmpty) return const [];
  return [
    EmployeeApiFilter(
      field: 'full_name',
      operator: 'contains',
      value: q,
    ),
  ];
}

class EmployeeApiPickerDrawer extends ConsumerStatefulWidget {
  const EmployeeApiPickerDrawer({
    super.key,
    required this.unit,
    required this.date,
    required this.onSelected,
  });

  final String unit;
  final String date;
  final ValueChanged<EmployeeRecord> onSelected;

  @override
  ConsumerState<EmployeeApiPickerDrawer> createState() =>
      _EmployeeApiPickerDrawerState();
}

class _EmployeeApiPickerDrawerState extends ConsumerState<EmployeeApiPickerDrawer> {
  static const int _pageLimit = 20;

  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _debouncedQuery = '';

  int _fetchGeneration = 0;

  final List<EmployeeRecord> _raw = [];
  int _apiTotal = 0;
  int _lastPageSize = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _loadError;

  List<EmployeeRecord> get _filtered {
    final filters = _localFiltersForQuery(_debouncedQuery);
    if (filters.isEmpty) return List<EmployeeRecord>.from(_raw);
    return _raw.where((e) {
      for (final f in filters) {
        if (!_matchesFilter(e, f)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadFromStart());
  }

  void _onSearchTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = _searchCtrl.text.trim());
      _reloadFromStart();
    });
  }

  bool get _serverHasMore {
    if (_apiTotal > 0) return _raw.length < _apiTotal;
    return _lastPageSize >= _pageLimit;
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

  Future<void> _maybePrefetchForEmptyFilter() async {
    if (_debouncedQuery.isEmpty) return;
    var guard = 0;
    while (mounted &&
        guard < 12 &&
        _debouncedQuery.isNotEmpty &&
        _filtered.isEmpty &&
        _serverHasMore &&
        !_loadingMore &&
        !_loading &&
        _loadError == null) {
      guard++;
      await _fetchNextPage();
    }
  }

  Future<void> _reloadFromStart() async {
    final gen = ++_fetchGeneration;
    setState(() {
      _raw.clear();
      _apiTotal = 0;
      _lastPageSize = 0;
      _loadError = null;
      _loading = true;
      _loadingMore = false;
    });
    await _fetchNextPage(expectedGen: gen);
    if (mounted && gen == _fetchGeneration) {
      await _maybePrefetchForEmptyFilter();
    }
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
      final params = EmployeesQueryParams(
        unit: widget.unit,
        date: widget.date,
        skip: _raw.length,
        limit: _pageLimit,
        sort: const [],
        localFilters: const [],
      );
      final service = ref.read(employeesApiServiceProvider);
      final cookieHeader = ref.read(hrCookieHeaderProvider);
      final result = await service.fetchEmployees(
        params: params,
        cookieHeader: cookieHeader,
      );
      if (!mounted || gen != _fetchGeneration) return;
      if (!result.isSuccess) {
        throw EmployeesApiException('API Status: ${result.status}');
      }
      setState(() {
        _raw.addAll(result.employees);
        _apiTotal = result.total;
        _lastPageSize = result.employees.length;
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
  void didUpdateWidget(covariant EmployeeApiPickerDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit != widget.unit || oldWidget.date != widget.date) {
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final hasMore = _serverHasMore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          title: const Text('Select employee'),
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
              hintText: 'Search employee by name',
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
          child: _buildBody(context, filtered, hasMore),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<EmployeeRecord> filtered,
    bool hasMore,
  ) {
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

    if (_loading && _raw.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _debouncedQuery.isEmpty ? 'No employees' : 'No matches (try scrolling if more are loading)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    final subtitle = _debouncedQuery.isEmpty
        ? (_apiTotal > 0
            ? '${filtered.length} shown · $_apiTotal total'
            : '${filtered.length} shown')
        : (_apiTotal > 0
            ? '${filtered.length} match · ${_raw.length} / $_apiTotal loaded'
            : '${filtered.length} match · ${_raw.length} loaded');

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filtered.length + (hasMore && _loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= filtered.length) {
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
                  final e = filtered[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0)
                        const Divider(height: 1, color: VmsColors.border),
                      ListTile(
                        key: ValueKey<String>('${e.id}-${e.empCode}-$index'),
                        title: Text(
                          e.fullName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${e.empCode} · ${e.designationName ?? '-'}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        onTap: () => widget.onSelected(e),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        if (_loadingMore && filtered.isNotEmpty)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
