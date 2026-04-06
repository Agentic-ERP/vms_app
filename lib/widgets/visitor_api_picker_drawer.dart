import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor_api_filter.dart';
import '../models/visitor_record.dart';
import '../models/visitors_query_params.dart';
import '../providers/visitors_list_provider.dart';
import '../theme/app_theme.dart';

/// Right drawer: search by `full_name` (contains) and list API visitors.
class VisitorApiPickerDrawer extends ConsumerStatefulWidget {
  const VisitorApiPickerDrawer({
    super.key,
    required this.onSelected,
  });

  final ValueChanged<VisitorRecord> onSelected;

  @override
  ConsumerState<VisitorApiPickerDrawer> createState() =>
      _VisitorApiPickerDrawerState();
}

class _VisitorApiPickerDrawerState extends ConsumerState<VisitorApiPickerDrawer> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _debouncedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    final text = _searchCtrl.text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = text.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchTextChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  VisitorsQueryParams _params() {
    final q = _debouncedQuery;
    return VisitorsQueryParams(
      skip: 0,
      limit: 50,
      filter: q.isEmpty
          ? const []
          : [
              VisitorApiFilter(
                field: 'full_name',
                operator: 'contains',
                value: q,
              ),
            ],
      sort: const [],
    );
  }

  Widget _visitorAvatar(VisitorRecord v) {
    final url = (v.photoUrls != null && v.photoUrls!.isNotEmpty)
        ? v.photoUrls!.first
        : null;

    Widget fallback() => const CircleAvatar(
          radius: 20,
          backgroundColor: VmsColors.fieldFill,
          child: Icon(Icons.person_outline, color: Colors.white70),
        );

    if (url == null || url.isEmpty) return fallback();

    return ClipOval(
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = _params();
    final async = ref.watch(visitorsListProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: VmsColors.card,
          foregroundColor: Colors.white,
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
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
          child: async.when(
            data: (result) {
              if (result.visitors.isEmpty) {
                return Center(
                  child: Text(
                    'No visitors',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      '${result.visitors.length} shown · ${result.totalCount} total',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: result.visitors.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: VmsColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final v = result.visitors[index];
                        return ListTile(
                          leading: _visitorAvatar(v),
                          title: Text(
                            v.fullName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${v.phoneNumber} · ${v.companyName}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => widget.onSelected(v),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(visitorsListProvider(params)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
