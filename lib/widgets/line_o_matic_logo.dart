import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Line-O-Matic wordmark from bundled asset.
class LineOMaticLogo extends StatelessWidget {
  const LineOMaticLogo({
    super.key,
    this.height = 40,
    this.alignment = Alignment.center,
    /// Compensates for extra transparent padding in the PNG (negative moves the mark up).
    this.visualVerticalOffset = 0,
  });

  final double height;
  final AlignmentGeometry alignment;

  /// Pixels to shift the asset on screen (negative = up).
  final double visualVerticalOffset;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      kLineOMaticLogoAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Text(
        'LINE-O-MATIC',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: VmsColors.primaryCyan,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
      ),
    );

    if (visualVerticalOffset != 0) {
      image = Transform.translate(
        offset: Offset(0, visualVerticalOffset),
        child: image,
      );
    }

    return Align(
      alignment: alignment,
      child: image,
    );
  }
}
