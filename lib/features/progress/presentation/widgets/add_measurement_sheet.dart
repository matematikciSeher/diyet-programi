import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/models/progress_report.dart';
import '../progress_labels.dart';

/// Vücut ölçüleri girişi; kaydedilirse yeni (id'siz) [BodyMeasurement] döner.
Future<BodyMeasurement?> showAddMeasurementSheet(
  BuildContext context, {
  required DateTime now,
  List<MeasurementTrend> previous = const [],
}) => showModalBottomSheet<BodyMeasurement>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AddMeasurementSheet(now: now, previous: previous),
);

class _AddMeasurementSheet extends StatefulWidget {
  const _AddMeasurementSheet({required this.now, required this.previous});

  final DateTime now;
  final List<MeasurementTrend> previous;

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _form = GlobalKey<FormState>();
  final _controllers = {
    for (final f in MeasurementField.values) f: TextEditingController(),
  };
  String? _error;
  late DateTime _date = widget.now;

  Future<void> _pickDate() async {
    final now = widget.now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _date =
          picked.year == now.year &&
              picked.month == now.month &&
              picked.day == now.day
          ? now
          : DateTime(picked.year, picked.month, picked.day, 8),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _value(MeasurementField f) =>
      ProgressFormat.parse(_controllers[f]!.text);

  String? _validate(MeasurementField field, String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final value = ProgressFormat.parse(text);
    final (min, max) = field.validRange;
    if (value == null || value < min || value > max) {
      return context.l10n.errorOutOfRange(
        AppFormat.integer(context, min),
        AppFormat.integer(context, max),
      );
    }
    return null;
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (MeasurementField.values.every((f) => _value(f) == null)) {
      setState(() => _error = context.l10n.progressMeasurementNeedsValue);
      return;
    }
    Navigator.of(context).pop(
      BodyMeasurement(
        id: '',
        recordedAt: _date,
        waistCm: _value(MeasurementField.waist),
        hipCm: _value(MeasurementField.hip),
        chestCm: _value(MeasurementField.chest),
        neckCm: _value(MeasurementField.neck),
        armCm: _value(MeasurementField.arm),
        thighCm: _value(MeasurementField.thigh),
        bodyFatPercent: _value(MeasurementField.bodyFat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final previous = {for (final t in widget.previous) t.field: t.latest};
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.progressMeasurementSheetTitle,
                style: context.textStyles.titleLarge,
              ),
              AppSpacing.gapSm,
              Text(
                l10n.progressMeasurementHint,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapLg,
              Text(
                l10n.progressDateField,
                style: context.textStyles.labelLarge,
              ),
              AppSpacing.gapSm,
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(AppFormat.date(context, _date)),
              ),
              AppSpacing.gapLg,
              for (final field in MeasurementField.values) ...[
                AppTextField(
                  controller: _controllers[field],
                  label: field.label(l10n),
                  hint: previous[field] == null
                      ? null
                      : AppFormat.decimal(context, previous[field]!),
                  suffixText: field.unit(l10n),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,3}([.,]\d?)?'),
                    ),
                  ],
                  textInputAction: field == MeasurementField.values.last
                      ? TextInputAction.done
                      : TextInputAction.next,
                  validator: (v) => _validate(field, v),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                AppSpacing.gapMd,
              ],
              if (_error != null) ...[
                Text(
                  _error!,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
                AppSpacing.gapMd,
              ],
              AppSpacing.gapSm,
              FilledButton(onPressed: _submit, child: Text(l10n.actionSave)),
            ],
          ),
        ),
      ),
    );
  }
}
