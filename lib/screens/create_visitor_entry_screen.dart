import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/create_visitor_log_request.dart';
import '../models/employee_record.dart';
import '../models/purpose_query_params.dart';
import '../models/visitor_api_filter.dart';
import '../models/visitor_record.dart';
import '../providers/create_visitor_log_provider.dart';
import '../providers/purpose_reasons_provider.dart';
import '../widgets/employee_api_picker_drawer.dart';
import '../widgets/register_new_visitor_form.dart';
import '../widgets/visitor_api_picker_drawer.dart';
import '../providers/selected_unit_provider.dart';
import '../theme/app_theme.dart';

enum _PickerKind { employee, visitor }

class CreateVisitorEntryScreen extends ConsumerStatefulWidget {
  const CreateVisitorEntryScreen({super.key});

  @override
  ConsumerState<CreateVisitorEntryScreen> createState() =>
      _CreateVisitorEntryScreenState();
}

class _CreateVisitorEntryScreenState
    extends ConsumerState<CreateVisitorEntryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _tabIndex = 0;
  _PickerKind? _pickerKind;

  final _employeeNameCtrl = TextEditingController();
  final _visitorNameCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _visitorCountCtrl = TextEditingController(text: '1');
  late final TextEditingController _dateDisplayCtrl;
  late final TextEditingController _timeDisplayCtrl;

  TimeOfDay? _inwardTime;
  bool _employeeApproved = false;
  bool _entryAllowed = false;
  String? _selectedVisitorId;
  String? _selectedEmployeeCode;
  String? _selectedEmployeeId;
  int? _selectedReasonId;

  @override
  void initState() {
    super.initState();
    _dateDisplayCtrl = TextEditingController(text: _formatDate(DateTime.now()));
    _timeDisplayCtrl = TextEditingController(text: '--:--');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final unit = ref.read(selectedUnitProvider).valueOrNull;
      if (unit != null && mounted) {
        _unitCtrl.text = '$unit';
      }
    });
  }

  @override
  void dispose() {
    _employeeNameCtrl.dispose();
    _visitorNameCtrl.dispose();
    _reasonCtrl.dispose();
    _unitCtrl.dispose();
    _visitorCountCtrl.dispose();
    _dateDisplayCtrl.dispose();
    _timeDisplayCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}-${two(d.month)}-${d.year}';
  }

  static String _formatTime24h(TimeOfDay t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _inwardTime ?? TimeOfDay.now(),
    );
    if (picked == null || !context.mounted) return;
    setState(() => _inwardTime = picked);
    _timeDisplayCtrl.text = _formatTime24h(picked);
  }

  void _openPicker(_PickerKind kind) {
    FocusScope.of(context).unfocus();
    setState(() => _pickerKind = kind);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  void _onDrawerChanged(bool opened) {
    if (!opened && mounted) {
      setState(() => _pickerKind = null);
    }
  }

  Future<void> _switchUnit() async {
    await ref.read(selectedUnitProvider.notifier).clearUnit();
  }

  Future<void> _handleBack() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
      return;
    }
    await _switchUnit();
  }

  Widget _requiredLabel(String text) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' *',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }

  Widget _plainLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _twoColumnRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.sizeOf(context);
    final drawerWidth = math.min(360.0, mq.width * 0.42);
    final submitAsync = ref.watch(createVisitorLogControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: VmsColors.background,
      onEndDrawerChanged: _onDrawerChanged,
      endDrawer: (_tabIndex != 0 || _pickerKind == null)
          ? null
          : Drawer(
              width: drawerWidth,
              backgroundColor: VmsColors.card,
              child: _pickerKind == _PickerKind.employee
                  ? EmployeeApiPickerDrawer(
                      unit: _unitCtrl.text.trim().isEmpty ? '1' : _unitCtrl.text.trim(),
                      date: _dateDisplayCtrl.text,
                      onSelected: (EmployeeRecord employee) {
                        setState(() {
                          _employeeNameCtrl.text = employee.fullName;
                          _selectedEmployeeCode = employee.empCode;
                          _selectedEmployeeId = employee.id;
                        });
                        _scaffoldKey.currentState?.closeEndDrawer();
                      },
                    )
                  : VisitorApiPickerDrawer(
                      onSelected: (VisitorRecord v) {
                        setState(() {
                          _visitorNameCtrl.text = v.fullName;
                          _selectedVisitorId = v.visitorId;
                        });
                        _scaffoldKey.currentState?.closeEndDrawer();
                      },
                    ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Create Visitor Entry',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Change unit',
                    onPressed: _switchUnit,
                    icon: const Icon(Icons.swap_horiz),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ModeTabs(
                tabIndex: _tabIndex,
                onChanged: (index) => setState(() => _tabIndex = index),
              ),
              const SizedBox(height: 20),
              if (_tabIndex == 0) ...[
                _buildAddEntryForm(),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: VmsColors.createGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                    ),
                    onPressed: submitAsync.isLoading ? null : _handleSubmit,
                    child: submitAsync.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Visitor'),
                  ),
                ),
              ] else
                const RegisterNewVisitorForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddEntryForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _twoColumnRow(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _requiredLabel('Employee Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _employeeNameCtrl,
                    readOnly: true,
                    onTap: () => _openPicker(_PickerKind.employee),
                    decoration: const InputDecoration(
                      hintText: 'Employee Name',
                      suffixIcon: Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _requiredLabel('Visitor Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _visitorNameCtrl,
                    readOnly: true,
                    onTap: () => _openPicker(_PickerKind.visitor),
                    decoration: const InputDecoration(
                      hintText: 'Visitor Name',
                      suffixIcon: Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _twoColumnRow(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _requiredLabel('Inward Date'),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true,
                    controller: _dateDisplayCtrl,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.lock_outline, size: 20),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _requiredLabel('Inward Time'),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true,
                    onTap: _pickTime,
                    controller: _timeDisplayCtrl,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.access_time, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _requiredLabel('Reason for Visit'),
            const SizedBox(height: 8),
            _buildReasonDropdown(),
            const SizedBox(height: 20),
            _twoColumnRow(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _requiredLabel('Unit'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _unitCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'Unit',
                      suffixIcon: Icon(Icons.lock_outline, size: 20),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _requiredLabel('Number of Visitors'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _visitorCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Number of Visitors',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _twoColumnRow(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _plainLabel('Employee Approved'),
                  const SizedBox(height: 8),
                  Checkbox(
                    value: _employeeApproved,
                    onChanged: (v) =>
                        setState(() => _employeeApproved = v ?? false),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _plainLabel('Entry Allowed'),
                  const SizedBox(height: 8),
                  Checkbox(
                    value: _entryAllowed,
                    onChanged: (v) =>
                        setState(() => _entryAllowed = v ?? false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonDropdown() {
    final params = PurposeQueryParams(
      skip: 0,
      limit: 50,
      filter: const [
        VisitorApiFilter(
          field: 'status',
          operator: 'contains',
          value: 'A',
        ),
      ],
      sort: const [],
    );
    final asyncReasons = ref.watch(purposeReasonsProvider(params));

    return asyncReasons.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failed to load reasons',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.invalidate(purposeReasonsProvider(params)),
            child: const Text('Retry'),
          ),
        ],
      ),
      data: (result) {
        final items = result.reasons
            .where((r) => r.reason.trim().isNotEmpty)
            .toList(growable: false);
        final selected = items.any((r) => r.id == _selectedReasonId)
            ? _selectedReasonId
            : null;

        return DropdownButtonFormField<int>(
          value: selected,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          items: items
              .map(
                (r) => DropdownMenuItem<int>(
                  value: r.id,
                  child: Text(r.reason),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            setState(() {
              _selectedReasonId = value;
              String reasonText = '';
              for (final r in items) {
                if (r.id == value) {
                  reasonText = r.reason;
                  break;
                }
              }
              _reasonCtrl.text = reasonText;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Select reason',
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    final visitorId = _selectedVisitorId;
    final employeeCode = _selectedEmployeeCode;
    final employeeId = _selectedEmployeeId;
    final reason = _reasonCtrl.text.trim();
    final employeeName = _employeeNameCtrl.text.trim();
    final visitorName = _visitorNameCtrl.text.trim();
    final unit = _unitCtrl.text.trim();
    final countOfVisitors = _visitorCountCtrl.text.trim();

    if (visitorId == null ||
        visitorId.isEmpty ||
        employeeCode == null ||
        employeeCode.isEmpty ||
        employeeId == null ||
        employeeId.isEmpty ||
        reason.isEmpty ||
        employeeName.isEmpty ||
        visitorName.isEmpty ||
        unit.isEmpty ||
        countOfVisitors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill/select all required fields')),
      );
      return;
    }

    final request = CreateVisitorLogRequest(
      visitorId: visitorId,
      reason: reason,
      employeeName: employeeName,
      visitorName: visitorName,
      employeeCode: employeeCode,
      hasEmployeeApproved: _employeeApproved,
      isEntryAllowed: _entryAllowed,
      unit: unit,
      employeeId: employeeId,
      countOfVisitors: countOfVisitors,
    );

    try {
      final response = await ref
          .read(createVisitorLogControllerProvider.notifier)
          .submit(request);
      if (!mounted) return;
      if (response.isSuccess) {
        _clearFormAfterSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visitor log created successfully (${response.status})')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Create failed: ${response.status}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  void _clearFormAfterSuccess() {
    setState(() {
      _employeeNameCtrl.clear();
      _visitorNameCtrl.clear();
      _reasonCtrl.clear();
      _visitorCountCtrl.text = '1';
      _timeDisplayCtrl.text = '--:--';

      _inwardTime = null;
      _employeeApproved = false;
      _entryAllowed = false;

      _selectedVisitorId = null;
      _selectedEmployeeCode = null;
      _selectedEmployeeId = null;
      _selectedReasonId = null;
    });
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.tabIndex,
    required this.onChanged,
  });

  final int tabIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Add Visitor Entry Form',
            selected: tabIndex == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabButton(
            label: 'Register New Visitor',
            selected: tabIndex == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? VmsColors.tabActiveBlue : VmsColors.fieldFill,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
