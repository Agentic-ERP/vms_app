/// One frame of the Automate Gate Inward SSE stream.
///
/// The API emits `event: message|end|error` frames whose `data:` line is a
/// JSON object shaped `{status, message, data: {event, message, ...}}`.
/// `data.event` names the pipeline step (`started`, `validating`,
/// `validated`, `extracting`, `document_extracted`, `extracted_data`,
/// `verifying`, `interrelation_verified`, `storing`, `completed`) and is
/// absent on the terminal `end`/`error` frames.
class GateInwardSseEvent {
  GateInwardSseEvent({required this.sseType, required this.raw});

  /// The SSE `event:` line value.
  final String sseType;

  /// Full decoded JSON body from the `data:` line.
  final Map<String, dynamic> raw;

  Map<String, dynamic>? get payload => raw['data'] as Map<String, dynamic>?;

  /// Pipeline step name (see class doc), or null on `end`/`error` frames.
  String? get step => payload?['event'] as String?;

  String? get stepMessage =>
      payload?['message'] as String? ?? raw['message'] as String?;

  /// Human-friendly progress line. `document_extracted` carries no
  /// `data.message` of its own (only `filename`/`status`), so this builds
  /// one. A failed `interrelation_verified` carries a long essay listing
  /// every failure in its `message` — that's already shown, per-check,
  /// with red/green icons in the verification card, so this is kept
  /// short here instead of duplicating it. Every other step just uses
  /// [stepMessage].
  String? get displayMessage {
    if (step == 'document_extracted') {
      final filename = payload?['filename'] as String?;
      final status = payload?['status'] as String?;
      if (filename != null) {
        return status == 'completed' ? 'Extracted: $filename' : '$filename: ${status ?? 'failed'}';
      }
    }
    if (step == 'interrelation_verified' && verificationStatus == 'failed') {
      return 'Cross-document verification failed';
    }
    return stepMessage;
  }

  /// True for a dedicated `event: error` frame, and also for the terminal
  /// `event: end` frame this backend sends when the pipeline fails after
  /// verification (its `data.event` is `"error"` in that case).
  bool get isError => sseType == 'error' || step == 'error';

  bool get isEnd => sseType == 'end';

  /// Only populated on the `completed` step.
  Map<String, dynamic>? get completedData {
    if (step != 'completed') return null;
    return payload?['data'] as Map<String, dynamic>?;
  }

  /// Only populated on the `extracted_data` step: the structured OCR
  /// output keyed by document type (`invoice`, `eway_bill`, `lr_receipt`).
  Map<String, dynamic>? get extractedData {
    if (step != 'extracted_data') return null;
    return payload?['data'] as Map<String, dynamic>?;
  }

  /// Only populated on the `interrelation_verified` step: the itemized
  /// cross-document checks, each with a `name` and pass/fail `status`.
  List<dynamic>? get verificationChecks {
    if (step != 'interrelation_verified') return null;
    return payload?['checks'] as List<dynamic>?;
  }

  /// Only populated on the `interrelation_verified` step: `"passed"` or
  /// `"failed"` overall result.
  String? get verificationStatus {
    if (step != 'interrelation_verified') return null;
    return payload?['status'] as String?;
  }

  /// Only populated on an error frame.
  List<dynamic>? get failedReasons =>
      payload?['failed_reasons'] as List<dynamic>?;
}
