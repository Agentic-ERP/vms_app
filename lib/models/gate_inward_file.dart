import 'dart:typed_data';

/// One file to upload for a gate-inward document slot (a slot can now hold
/// more than one file, e.g. a multi-page LR receipt).
class GateInwardFile {
  const GateInwardFile({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}
