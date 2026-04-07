import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor_api_filter.dart';
import '../models/visitor_log_record.dart';
import '../models/visitor_logs_query_params.dart';
import '../models/verify_visitor_log_otp_request.dart';
import '../providers/verify_visitor_log_otp_provider.dart';
import '../providers/visitor_logs_provider.dart';
import '../theme/app_theme.dart';

class CheckoutVisitorLogsScreen extends ConsumerStatefulWidget {
  const CheckoutVisitorLogsScreen({super.key});

  @override
  ConsumerState<CheckoutVisitorLogsScreen> createState() =>
      _CheckoutVisitorLogsScreenState();
}

class _CheckoutVisitorLogsScreenState
    extends ConsumerState<CheckoutVisitorLogsScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _verifiedVisitIds = <String>{};
  int _skip = 0;
  static const int _limit = 10;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _todayApiDate() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  VisitorLogsQueryParams _params() {
    return VisitorLogsQueryParams(
      skip: _skip,
      limit: _limit,
      filter: [
        VisitorApiFilter(
          field: 'inward_at',
          operator: 'date equals',
          value: _todayApiDate(),
        ),
      ],
      sort: const [
        {'colId': 'inward_at', 'sort': 'desc'},
      ],
      search: _searchCtrl.text.trim(),
    );
  }

  Future<void> _showVerifyOtpDialog(VisitorLogRecord log) async {
    final ctrl = TextEditingController();
    final enteredOtp = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VmsColors.card,
        title: const Text('Verify OTP'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter 4-digit OTP',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (!mounted || enteredOtp == null || enteredOtp.isEmpty) return;

    final req = VerifyVisitorLogOtpRequest(
      visitId: log.visitId,
      otp: enteredOtp,
    );
    try {
      final response = await ref
          .read(verifyVisitorLogOtpControllerProvider.notifier)
          .submit(req);
      if (!mounted) return;
      if (response.isSuccess) {
        setState(() {
          _verifiedVisitIds.add(log.visitId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP verified (${response.status})')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  Widget _statusDot(bool value) {
    return Icon(
      value ? Icons.check_circle : Icons.cancel,
      color: value ? Colors.green : Colors.redAccent,
      size: 18,
    );
  }

  Widget _meta(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Colors.white70),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildLogCard(VisitorLogRecord log) {
    final rawOut = log.outwardAt?.trim();
    final outward = (rawOut == null ||
            rawOut.isEmpty ||
            rawOut.toLowerCase() == 'null')
        ? 'Still Inside'
        : rawOut;
    final hasCheckedOut = outward != 'Still Inside';
    final isVerified = _verifiedVisitIds.contains(log.visitId);
    final photoUrl =
        (log.visitorPhoto != null && log.visitorPhoto!.isNotEmpty) ? log.visitorPhoto!.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: VmsColors.fieldFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(Icons.person_outline, color: Colors.white70)
                      : Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_outline,
                            color: Colors.white70,
                          ),
                        ),
                ),
                Expanded(
                  child: Text(
                    log.visitorName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VmsColors.fieldFill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Unit-${log.unit}', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _meta('Employee', '${log.employeeCode} • ${log.employeeName}'),
                _meta('Reason', log.reason),
                _meta('Count', log.countOfVisitors),
                _meta('Inward', log.inwardAt),
                _meta('Outward', outward),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Approved'),
                const SizedBox(width: 6),
                _statusDot(log.hasEmployeeApproved),
                const SizedBox(width: 14),
                const Text('Entry'),
                const SizedBox(width: 6),
                _statusDot(log.isEntryAllowed),
                const Spacer(),
                if (hasCheckedOut)
                  Text(
                    'Out: $outward',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (isVerified)
                  const Chip(
                    label: Text('Verified'),
                    backgroundColor: Colors.green,
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: VmsColors.tabActiveBlue,
                    ),
                    onPressed: () => _showVerifyOtpDialog(log),
                    child: const Text('Verify OTP'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = _params();
    final asyncLogs = ref.watch(visitorLogsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => setState(() => _skip = 0),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => setState(() => _skip = 0),
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: asyncLogs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$error', textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => ref.invalidate(visitorLogsProvider(params)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (result) {
                  if (result.logs.isEmpty) {
                    return const Center(child: Text('No visitor logs found'));
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: result.logs.length,
                          itemBuilder: (context, index) =>
                              _buildLogCard(result.logs[index]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${result.logs.length} shown • ${result.totalCount} total'),
                          const Spacer(),
                          IconButton(
                            onPressed: _skip == 0
                                ? null
                                : () => setState(() => _skip = (_skip - _limit).clamp(0, 1 << 30)),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('${(_skip ~/ _limit) + 1}'),
                          IconButton(
                            onPressed: (_skip + _limit) >= result.totalCount
                                ? null
                                : () => setState(() => _skip += _limit),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
