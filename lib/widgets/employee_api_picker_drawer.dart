import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_api_filter.dart';
import '../models/employee_record.dart';
import '../models/employees_query_params.dart';
import '../providers/employees_list_provider.dart';
import '../theme/app_theme.dart';

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
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _debouncedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchTextChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  EmployeesQueryParams _params() {
    final q = _debouncedQuery;
    return EmployeesQueryParams(
      unit: widget.unit,
      date: widget.date,
      skip: 0,
      limit: 100,
      sort: const [],
      localFilters: q.isEmpty
          ? const []
          : [
              EmployeeApiFilter(
                field: 'full_name',
                operator: 'contains',
                value: q,
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = _params();
    final async = ref.watch(employeesListProvider(params));

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
          child: async.when(
            data: (result) {
              if (result.employees.isEmpty) {
                return Center(
                  child: Text(
                    'No employees',
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
                      '${result.employees.length} shown · ${result.total} total',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: result.employees.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: VmsColors.border),
                      itemBuilder: (context, index) {
                        final e = result.employees[index];
                        return ListTile(
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(employeesListProvider(params)),
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
