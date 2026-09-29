import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/gate_inward_file.dart';
import '../services/automate_gate_inward_service.dart';
import '../theme/app_theme.dart';

enum _GateDocType { ewayBill, invoice, lrReceipt }

enum _PickChoice { camera, gallery, pdfFile }

class _GateDocument {
  Uint8List? bytes;
  String? filename;

  bool get isPdf => (filename ?? '').toLowerCase().endsWith('.pdf');
}

/// Gate-inward automation: driver/visitor uploads the E-Way Bill, Invoice
/// and LR Receipt at the gate. The backend OCRs all 3, cross-verifies them
/// against each other, and stores the consignment — streamed back as
/// Server-Sent Events via [AutomateGateInwardService.process].
class AutomateGateInwardForm extends StatefulWidget {
  const AutomateGateInwardForm({super.key});

  @override
  State<AutomateGateInwardForm> createState() => _AutomateGateInwardFormState();
}

class _AutomateGateInwardFormState extends State<AutomateGateInwardForm> {
  final ImagePicker _picker = ImagePicker();
  final AutomateGateInwardService _service = AutomateGateInwardService();
  final Map<_GateDocType, List<_GateDocument>> _docs = {
    _GateDocType.ewayBill: [],
    _GateDocType.invoice: [],
    _GateDocType.lrReceipt: [],
  };
  bool _isProcessing = false;
  String? _currentStep;
  String? _consignmentNumber;
  String? _errorMessage;
  List<dynamic>? _failedReasons;
  Map<String, dynamic>? _extractedData;
  List<dynamic>? _verificationChecks;
  String? _verificationStatus;

  static const _labels = {
    _GateDocType.ewayBill: 'E-Way Bill',
    _GateDocType.invoice: 'Invoice',
    _GateDocType.lrReceipt: 'LR Receipt',
  };

  bool get _allDocsReady => _docs.values.every((list) => list.isNotEmpty);

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _addImage(_GateDocType type, ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _docs[type]!.add(
          _GateDocument()
            ..bytes = bytes
            ..filename = file.name.isNotEmpty
                ? file.name
                : '${type.name}_${_docs[type]!.length}.jpg',
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${source.name}: $e')),
      );
    }
  }

  Future<void> _addMultiImages(_GateDocType type) async {
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (files.isEmpty) return;

      final newDocs = <_GateDocument>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        newDocs.add(
          _GateDocument()
            ..bytes = bytes
            ..filename = file.name.isNotEmpty
                ? file.name
                : '${type.name}_${newDocs.length}.jpg',
        );
      }
      if (!mounted) return;
      setState(() => _docs[type]!.addAll(newDocs));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open gallery: $e')),
      );
    }
  }

  Future<void> _addPdfFiles(_GateDocType type) async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (picked.isEmpty) return;

      final newDocs = <_GateDocument>[];
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        newDocs.add(
          _GateDocument()
            ..bytes = bytes
            ..filename = file.name,
        );
      }
      if (!mounted) return;
      setState(() => _docs[type]!.addAll(newDocs));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open file picker: $e')));
    }
  }

  Future<void> _showSourcePicker(_GateDocType type) async {
    final choice = await showModalBottomSheet<_PickChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Upload PDF'),
              onTap: () => Navigator.of(context).pop(_PickChoice.pdfFile),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(context).pop(_PickChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(_PickChoice.gallery),
            ),
          ],
        ),
      ),
    );
    switch (choice) {
      case _PickChoice.pdfFile:
        await _addPdfFiles(type);
      case _PickChoice.camera:
        await _addImage(type, ImageSource.camera);
      case _PickChoice.gallery:
        await _addMultiImages(type);
      case null:
        break;
    }
  }

  void _removeDoc(_GateDocType type, int index) {
    setState(() => _docs[type]!.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_allDocsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all 3 documents')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStep = null;
      _consignmentNumber = null;
      _errorMessage = null;
      _failedReasons = null;
      _extractedData = null;
      _verificationChecks = null;
      _verificationStatus = null;
    });

    List<GateInwardFile> filesFor(_GateDocType type) => _docs[type]!
        .map((d) => GateInwardFile(bytes: d.bytes!, filename: d.filename!))
        .toList();

    try {
      final stream = _service.process(
        ewayBillFiles: filesFor(_GateDocType.ewayBill),
        invoiceFiles: filesFor(_GateDocType.invoice),
        lrReceiptFiles: filesFor(_GateDocType.lrReceipt),
      );

      await for (final event in stream) {
        if (!mounted) return;
        if (event.isError) {
          setState(() {
            _errorMessage = event.stepMessage ?? 'Automation failed';
            _failedReasons = event.failedReasons;
          });
          continue;
        }
        if (event.isEnd && event.payload == null) {
          continue; // generic stream-finished marker, nothing to show.
        }
        final completed = event.completedData;
        if (completed != null) {
          _consignmentNumber = completed['consignment_number'] as String?;
        }
        final extracted = event.extractedData;
        final checks = event.verificationChecks;
        final msg = event.displayMessage;
        setState(() {
          if (extracted != null) _extractedData = extracted;
          if (checks != null) {
            _verificationChecks = checks;
            _verificationStatus = event.verificationStatus;
          }
          if (msg != null) _currentStep = msg;
        });
        // Several steps (started/validating/validated/extracting, or the
        // 3 document_extracted events) can arrive within the same network
        // chunk, faster than a frame can paint — without this pause,
        // Flutter coalesces those setState calls and the user only ever
        // sees the last one, skipping the earlier steps visually.
        if (msg != null) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Automate Gate Inward',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            for (final type in _GateDocType.values) ...[
              _requiredLabel(context, _labels[type]!),
              const SizedBox(height: 8),
              _documentSection(type),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: VmsColors.createGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                onPressed: _isProcessing ? null : _submit,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.qr_code_scanner),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Automate Gate Inward',
                ),
              ),
            ),
            if (_currentStep != null || _errorMessage != null) ...[
              const SizedBox(height: 20),
              _progressPanel(context),
            ],
            if (_extractedData != null) ...[
              const SizedBox(height: 12),
              _extractedDataPanel(context),
            ],
            if (_verificationChecks != null) ...[
              const SizedBox(height: 12),
              _verificationPanel(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progressPanel(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VmsColors.fieldFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_currentStep != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isProcessing ? Icons.hourglass_top : Icons.check_circle,
                  size: 16,
                  color: _isProcessing ? muted : VmsColors.createGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentStep!,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
              ],
            ),
          if (_consignmentNumber != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.task_alt,
                  size: 16,
                  color: VmsColors.createGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consignment created: $_consignmentNumber',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: VmsColors.createGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Skip this when verification already failed: the
          // Cross-Document Verification card below shows exactly which
          // checks failed with red/green icons, so repeating the same
          // thing as one long error paragraph here is redundant.
          if (_errorMessage != null && _verificationStatus != 'failed') ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            if (_failedReasons != null && _failedReasons!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final reason in _failedReasons!)
                      Text(
                        '• $reason',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: muted),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  /// snake_case/camelCase key -> "Title Case" label.
  String _prettyLabel(String key) {
    final spaced = key.replaceAll('_', ' ');
    return spaced
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Recursively renders any JSON value (map/list/scalar) as readable
  /// label/value rows, so the full raw payload can be shown on demand
  /// without hand-writing a field list for every possible key. Nested
  /// maps get a left accent bar; a list of objects (e.g. `transit_legs`,
  /// `checks`) renders each entry as its own small card.
  Widget _jsonNode(
    BuildContext context,
    String label,
    dynamic value, {
    int depth = 0,
  }) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final outline = Theme.of(context).colorScheme.outline;

    if (value is Map) {
      if (value.isEmpty) return _kvRow(context, label, '—');
      return Container(
        margin: EdgeInsets.only(top: 6, left: depth == 0 ? 0 : 10),
        padding: depth == 0 ? EdgeInsets.zero : const EdgeInsets.only(left: 10),
        decoration: depth == 0
            ? null
            : BoxDecoration(
                border: Border(left: BorderSide(color: outline, width: 2)),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _prettyLabel(label),
              style: TextStyle(
                fontSize: depth == 0 ? 13 : 12,
                fontWeight: FontWeight.w700,
                color: depth == 0 ? VmsColors.primaryCyan : muted,
              ),
            ),
            for (final e in value.entries)
              _jsonNode(context, e.key.toString(), e.value, depth: depth + 1),
          ],
        ),
      );
    }

    if (value is List) {
      if (value.isEmpty) return _kvRow(context, label, '—');
      final isListOfObjects = value.every((e) => e is Map);
      return Container(
        margin: EdgeInsets.only(top: 6, left: depth == 0 ? 0 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _prettyLabel(label),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
            if (isListOfObjects)
              for (var i = 0; i < value.length; i++)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VmsColors.fieldFill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in (value[i] as Map).entries)
                        _jsonNode(
                          context,
                          e.key.toString(),
                          e.value,
                          depth: depth + 1,
                        ),
                    ],
                  ),
                )
            else
              _kvRow(context, '', value.join(', ')),
          ],
        ),
      );
    }

    return _kvRow(context, label, value?.toString() ?? '—');
  }

  Widget _kvRow(BuildContext context, String label, String value) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 128,
              child: Text(
                _prettyLabel(label),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullDetailsExpander(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        title: Text(
          'View full details',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: VmsColors.primaryCyan,
          ),
        ),
        children: children,
      ),
    );
  }

  Widget _extractedDataPanel(BuildContext context) {
    final data = _extractedData!;
    final invoice = data['invoice'] as Map<String, dynamic>?;
    final ewayBill = data['eway_bill'] as Map<String, dynamic>?;
    final lr = data['lr_receipt'] as Map<String, dynamic>?;
    final supplier = invoice?['supplier'] as Map<String, dynamic>?;
    final buyer = invoice?['buyer'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VmsColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extracted Data',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          if (invoice != null) ...[
            _kv(context, 'Invoice No.', invoice['invoice_number']?.toString()),
            _kv(context, 'Invoice Date', invoice['invoice_date']?.toString()),
            _kv(context, 'Supplier', supplier?['name']?.toString()),
            _kv(context, 'Supplier GSTIN', supplier?['gstin']?.toString()),
            _kv(context, 'Buyer', buyer?['name']?.toString()),
            _kv(context, 'Buyer GSTIN', buyer?['gstin']?.toString()),
            _kv(context, 'Total Amount', invoice['total_amount']?.toString()),
          ],
          if (ewayBill != null)
            _kv(
              context,
              'E-Way Bill No.',
              ewayBill['eway_bill_number']?.toString(),
            ),
          if (lr != null) _kv(context, 'LR No.', lr['lr_number']?.toString()),
          _fullDetailsExpander(
            context,
            children: [
              for (final e in data.entries) _jsonNode(context, e.key, e.value),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verificationPanel(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final passed = _verificationStatus == 'passed';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VmsColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cross-Document Verification',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: passed
                    ? VmsColors.createGreen
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                _verificationStatus ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: passed
                      ? VmsColors.createGreen
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final check in _verificationChecks ?? const [])
            if (check is Map)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      check['status'] == 'passed'
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 14,
                      color: check['status'] == 'passed'
                          ? VmsColors.createGreen
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        check['name']?.toString() ?? '',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ),
                  ],
                ),
              ),
          _fullDetailsExpander(
            context,
            children: [
              for (var i = 0; i < (_verificationChecks ?? const []).length; i++)
                if (_verificationChecks![i] is Map)
                  _jsonNode(context, 'Check ${i + 1}', _verificationChecks![i]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requiredLabel(BuildContext context, String text) {
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' *',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }

  /// The original full-width box per file (same look as before), stacked
  /// vertically, plus a trailing full-width "add" box — so a slot can
  /// hold more than one file (e.g. a multi-page LR receipt) instead of
  /// just one, without changing how any single box looks.
  Widget _documentSection(_GateDocType type) {
    final docs = _docs[type]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < docs.length; i++) ...[
          _fileTile(docs[i], onRemove: () => _removeDoc(type, i)),
          const SizedBox(height: 10),
        ],
        _addTile(type, hasExisting: docs.isNotEmpty),
      ],
    );
  }

  Widget _fileTile(_GateDocument doc, {required VoidCallback onRemove}) {
    final outline = Theme.of(context).colorScheme.outline;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      height: 110,
      decoration: BoxDecoration(
        border: Border.all(color: outline, width: 1.2),
        borderRadius: BorderRadius.circular(8),
        color: VmsColors.fieldFill,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          doc.isPdf
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          doc.filename ?? 'document.pdf',
                          style: TextStyle(color: muted, fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              : Image.memory(doc.bytes!, fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                iconSize: 16,
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile(_GateDocType type, {required bool hasExisting}) {
    final outline = Theme.of(context).colorScheme.outline;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      color: VmsColors.fieldFill,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSourcePicker(type),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            border: Border.all(color: outline, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasExisting ? Icons.add : Icons.upload_file_outlined,
                  color: muted,
                ),
                const SizedBox(height: 6),
                Text(
                  hasExisting
                      ? 'Add another ${_labels[type]}'
                      : 'Tap to upload ${_labels[type]}',
                  style: TextStyle(color: muted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
