import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/runtime_environment.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../food/data/datasources/sample_food_catalog.dart';
import '../../../food/data/repositories/food_repository_impl.dart';
import '../barcode_camera_permission.dart';
import '../barcode_scan_session.dart';
import '../widgets/barcode_scan_overlay.dart';
import '../widgets/live_barcode_camera.dart';

/// Barkodla ürün bulma: kamera taraması ve elle giriş.
///
/// Eşleşme her zaman [FoodRepository.findByBarcode] üzerinden yapılır.
class BarcodeScannerPage extends ConsumerStatefulWidget {
  const BarcodeScannerPage({
    super.key,
    this.meal,
    this.logDate,
    this.enableLiveCamera,
    this.initialPermission = BarcodeCameraPermission.unknown,
    this.cameraBuilder,
    this.onOpenSettings,
  });

  final MealType? meal;
  final DateTime? logDate;

  /// `null` ise widget testlerinde kamera kapatılır; cihazda açılır.
  final bool? enableLiveCamera;
  final BarcodeCameraPermission initialPermission;
  final BarcodeCameraBuilder? cameraBuilder;
  final Future<void> Function()? onOpenSettings;

  @override
  ConsumerState<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends ConsumerState<BarcodeScannerPage> {
  final _controller = TextEditingController();
  final _session = BarcodeScanSession();
  var _searching = false;
  var _scannerPaused = false;
  String? _notFoundCode;
  var _incompleteCatalog = false;
  late BarcodeCameraPermission _permission = widget.initialPermission;

  bool get _useLiveCamera {
    if (_permission == BarcodeCameraPermission.denied ||
        _permission == BarcodeCameraPermission.unsupported) {
      return false;
    }
    if (widget.cameraBuilder != null) return true;
    if (widget.enableLiveCamera != null) return widget.enableLiveCamera!;
    return !isFlutterTest;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    final custom = widget.onOpenSettings;
    if (custom != null) {
      await custom();
      return;
    }
    await openAppSettings();
  }

  Future<void> _lookup(String raw) async {
    final code = BarcodeScanSession.normalize(raw);
    if (code.isEmpty) return;
    AppLogger.debug(
      'Barcode lookup start: raw="$raw" normalized="$code" '
      'useFakeServices=${ref.read(appConfigProvider).useFakeServices}',
    );
    setState(() {
      _searching = true;
      _notFoundCode = null;
      _incompleteCatalog = false;
      _scannerPaused = true;
    });
    final result = await ref.read(foodRepositoryProvider).findByBarcode(code);
    if (!mounted) return;
    setState(() => _searching = false);
    result.when(
      success: (food) {
        if (food == null) {
          setState(() {
            _notFoundCode = code;
            _incompleteCatalog = false;
          });
          return;
        }
        context.pushReplacement(
          AppRoutes.foodDetailPath(
            food.id,
            meal: widget.meal,
            date: widget.logDate,
          ),
          extra: food,
        );
      },
      failure: (f) {
        if (f is IncompleteCatalogFoodFailure) {
          setState(() {
            _notFoundCode = code;
            _incompleteCatalog = true;
          });
          return;
        }
        _session.release(clearCode: true);
        setState(() => _scannerPaused = false);
        final unavailable = f is NetworkFailure || f is ServerFailure;
        context.showSnack(
          unavailable
              ? context.l10n.foodDatabaseUnavailable
              : f.localizedMessage(context),
        );
      },
    );
  }

  Future<void> _lookupManual() => _lookup(_controller.text);

  void _onBarcodeDetected(String raw) {
    if (!_session.tryAccept(raw)) return;
    unawaited(_lookup(raw));
  }

  void _scanAgain() {
    _session.release(clearCode: true);
    setState(() {
      _notFoundCode = null;
      _incompleteCatalog = false;
      _scannerPaused = false;
      _searching = false;
    });
  }

  void _createCustom(String code) {
    context.pushReplacement(
      AppRoutes.customFoodPath(
        meal: widget.meal,
        barcode: code,
        date: widget.logDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showDemo = ref.watch(appConfigProvider).useFakeServices;
    final notFound = _notFoundCode;
    final live = _useLiveCamera;
    final denied = _permission == BarcodeCameraPermission.denied;

    return Scaffold(
      backgroundColor: live ? Colors.black : null,
      appBar: AppBar(
        title: Text(l10n.featureBarcode),
        backgroundColor: live ? Colors.black : null,
        foregroundColor: live ? Colors.white : null,
      ),
      body: Column(
        children: [
          if (live)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.cameraBuilder?.call(
                        onDetect: _onBarcodeDetected,
                        paused: _scannerPaused || _searching,
                        onPermissionChanged: (value) {
                          if (mounted) setState(() => _permission = value);
                        },
                      ) ??
                      LiveBarcodeCamera(
                        onDetect: _onBarcodeDetected,
                        paused: _scannerPaused || _searching,
                        onPermissionChanged: (value) {
                          if (mounted) setState(() => _permission = value);
                        },
                      ),
                  const ColoredBox(color: Color(0x33000000)),
                  BarcodeScanOverlay(hint: l10n.barcodeAlignHint),
                  if (_searching)
                    ColoredBox(
                      color: Colors.black45,
                      child: Center(
                        child: LoadingView(message: l10n.barcodeSearching),
                      ),
                    ),
                ],
              ),
            )
          else if (denied)
            Expanded(child: _PermissionDenied(onOpenSettings: _openSettings)),
          if (live || denied)
            Material(
              color: context.colors.surface,
              child: SafeArea(
                top: false,
                child: _ManualLookupPanel(
                  controller: _controller,
                  searching: _searching,
                  live: live,
                  showDemo: showDemo,
                  notFound: notFound,
                  incompleteCatalog: _incompleteCatalog,
                  onLookup: _lookupManual,
                  onCreateCustom: _createCustom,
                  onScanAgain: _scanAgain,
                ),
              ),
            )
          else
            Expanded(
              child: Material(
                color: context.colors.surface,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    _ManualLookupPanel(
                      controller: _controller,
                      searching: _searching,
                      live: live,
                      showDemo: showDemo,
                      notFound: notFound,
                      incompleteCatalog: _incompleteCatalog,
                      onLookup: _lookupManual,
                      onCreateCustom: _createCustom,
                      onScanAgain: _scanAgain,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ManualLookupPanel extends StatelessWidget {
  const _ManualLookupPanel({
    required this.controller,
    required this.searching,
    required this.live,
    required this.showDemo,
    required this.onLookup,
    required this.onCreateCustom,
    required this.onScanAgain,
    this.notFound,
    this.incompleteCatalog = false,
  });

  final TextEditingController controller;
  final bool searching;
  final bool live;
  final bool showDemo;
  final String? notFound;
  final bool incompleteCatalog;
  final VoidCallback onLookup;
  final ValueChanged<String> onCreateCustom;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ResponsiveCenter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!live) AppSpacing.gapLg,
          SectionHeader(title: l10n.barcodeManualTitle),
          Semantics(
            textField: true,
            label: l10n.barcodeManualHint,
            child: AppTextField(
              controller: controller,
              hint: l10n.barcodeManualHint,
              prefixIcon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onLookup(),
            ),
          ),
          AppSpacing.gapLg,
          Semantics(
            button: true,
            label: l10n.barcodeSearch,
            child: AppButton(
              label: l10n.barcodeSearch,
              icon: Icons.search_rounded,
              isLoading: searching && !live,
              onPressed: onLookup,
            ),
          ),
          if (notFound != null) ...[
            AppSpacing.gapXl,
            Text(
              incompleteCatalog
                  ? l10n.barcodeIncompleteCatalog(notFound!)
                  : l10n.barcodeNotFound,
              style: context.textStyles.bodyMedium,
            ),
            AppSpacing.gapMd,
            Semantics(
              button: true,
              label: l10n.foodCreateCustom,
              child: AppButton.secondary(
                label: l10n.foodCreateCustom,
                icon: Icons.add_rounded,
                onPressed: () => onCreateCustom(notFound!),
              ),
            ),
            AppSpacing.gapSm,
            Semantics(
              button: true,
              label: l10n.barcodeScanAgain,
              child: AppButton.text(
                label: l10n.barcodeScanAgain,
                icon: Icons.qr_code_scanner_rounded,
                onPressed: onScanAgain,
              ),
            ),
          ],
          if (showDemo) ...[
            AppSpacing.gapXl,
            Text(
              l10n.barcodeDemoHint(SampleFoodCatalog.demoBarcodes.join(', ')),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onOpenSettings});

  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_photography_outlined,
            size: AppSizes.iconLg,
            color: context.colors.primary,
          ),
          AppSpacing.gapLg,
          Text(
            l10n.barcodeCameraPermissionTitle,
            style: context.textStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapSm,
          Text(
            l10n.barcodeCameraPermissionMessage,
            style: context.textStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapLg,
          Semantics(
            button: true,
            label: l10n.barcodeOpenSettings,
            child: AppButton.secondary(
              label: l10n.barcodeOpenSettings,
              icon: Icons.settings_rounded,
              onPressed: onOpenSettings,
            ),
          ),
        ],
      ),
    );
  }
}
