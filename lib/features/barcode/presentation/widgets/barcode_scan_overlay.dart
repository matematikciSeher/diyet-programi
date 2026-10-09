import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Kamera üzerinde barkod hizalama çerçevesi ve açıklama.
class BarcodeScanOverlay extends StatelessWidget {
  const BarcodeScanOverlay({super.key, required this.hint});

  final String hint;

  static const frameSize = Size(240, 140);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IgnorePointer(
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Semantics(
                label: hint,
                image: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: colors.primary, width: 3),
                  ),
                  child: SizedBox(
                    width: frameSize.width,
                    height: frameSize.height,
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.42),
              child: Padding(
                padding: AppSpacing.page,
                child: Text(
                  hint,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black87)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
