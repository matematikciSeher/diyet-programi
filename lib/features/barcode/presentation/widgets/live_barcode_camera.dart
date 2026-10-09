import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/services/barcode/barcode_digits.dart';
import '../barcode_camera_permission.dart';

typedef BarcodeDetected = void Function(String barcode);

typedef BarcodeCameraBuilder =
    Widget Function({
      required BarcodeDetected onDetect,
      required bool paused,
      required ValueChanged<BarcodeCameraPermission> onPermissionChanged,
    });

/// Canlı kamera önizlemesi. Widget testleri [cameraBuilder] ile değiştirir.
class LiveBarcodeCamera extends StatefulWidget {
  const LiveBarcodeCamera({
    super.key,
    required this.onDetect,
    required this.paused,
    required this.onPermissionChanged,
  });

  final BarcodeDetected onDetect;
  final bool paused;
  final ValueChanged<BarcodeCameraPermission> onPermissionChanged;

  @override
  State<LiveBarcodeCamera> createState() => _LiveBarcodeCameraState();
}

class _LiveBarcodeCameraState extends State<LiveBarcodeCamera> {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
  );

  var _reportedPermission = false;

  @override
  void didUpdateWidget(covariant LiveBarcodeCamera oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused == oldWidget.paused) return;
    if (widget.paused) {
      _controller.pause();
    } else {
      _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (widget.paused) return;
    final ranked = [...capture.barcodes]..sort(
      (a, b) => _formatRank(a.format).compareTo(_formatRank(b.format)),
    );
    for (final barcode in ranked) {
      final raw = barcode.rawValue;
      if (raw == null || BarcodeDigits.accept(raw) == null) continue;
      AppLogger.debug(
        'Barcode scan: format=${barcode.format.name} raw="$raw" '
        'length=${raw.length} digits=${BarcodeDigits.normalize(raw)}',
      );
      widget.onDetect(raw);
      return;
    }
  }

  static int _formatRank(BarcodeFormat format) => switch (format) {
    BarcodeFormat.ean13 => 0,
    BarcodeFormat.ean8 => 1,
    BarcodeFormat.upcA => 2,
    BarcodeFormat.upcE => 3,
    _ => 9,
  };

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
      errorBuilder: (context, error) {
        if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
          if (!_reportedPermission) {
            _reportedPermission = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onPermissionChanged(BarcodeCameraPermission.denied);
            });
          }
        } else if (error.errorCode == MobileScannerErrorCode.unsupported) {
          if (!_reportedPermission) {
            _reportedPermission = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onPermissionChanged(BarcodeCameraPermission.unsupported);
            });
          }
        }
        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: Icon(
              Icons.photo_camera_outlined,
              color: context.colors.onSurfaceVariant,
              size: AppSizes.iconLg,
            ),
          ),
        );
      },
    );
  }
}
