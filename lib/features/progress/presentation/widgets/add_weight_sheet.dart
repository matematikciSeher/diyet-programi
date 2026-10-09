import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../progress_labels.dart';

typedef WeightInput = ({double kg, DateTime date, String? note});

/// Kilo ve tarih girişi; kaydedilirse [WeightInput] döner.
/// [initialDate] verilmezse bugün seçili gelir. [withNote] açıksa isteğe
/// bağlı not alanı gösterilir.
Future<WeightInput?> showAddWeightSheet(
  BuildContext context, {
  required DateTime now,
  double? initialKg,
  DateTime? initialDate,
  bool withNote = false,
}) => showModalBottomSheet<WeightInput>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AddWeightSheet(
    now: now,
    initialKg: initialKg,
    initialDate: initialDate,
    withNote: withNote,
  ),
);

class _AddWeightSheet extends StatefulWidget {
  const _AddWeightSheet({
    required this.now,
    required this.withNote,
    this.initialKg,
    this.initialDate,
  });

  final DateTime now;
  final double? initialKg;
  final DateTime? initialDate;
  final bool withNote;

  @override
  State<_AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends State<_AddWeightSheet> {
  final _form = GlobalKey<FormState>();
  late final _kg = TextEditingController(
    text: widget.initialKg == null
        ? ''
        : widget.initialKg!.toStringAsFixed(1).replaceAll('.0', ''),
  );
  late DateTime _date = widget.initialDate ?? widget.now;
  final _note = TextEditingController();

  @override
  void dispose() {
    _kg.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _validate(String? text) {
    final l10n = context.l10n;
    final value = ProgressFormat.parse(text ?? '');
    if (value == null) return l10n.errorValueRequired;
    if (value < AppConstants.minWeightKg || value > AppConstants.maxWeightKg) {
      return l10n.errorOutOfRange(
        AppFormat.integer(context, AppConstants.minWeightKg),
        AppFormat.integer(context, AppConstants.maxWeightKg),
      );
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(widget.now.year - 5),
      lastDate: widget.now,
    );
    if (picked == null || !mounted) return;
    final isToday =
        picked.year == widget.now.year &&
        picked.month == widget.now.month &&
        picked.day == widget.now.day;
    // Geçmiş günler için saat bilgisi yok; sabah tartısı varsayılır.
    setState(
      () => _date = isToday
          ? widget.now
          : DateTime(picked.year, picked.month, picked.day, 8),
    );
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final note = _note.text.trim();
    Navigator.of(context).pop((
      kg: ProgressFormat.parse(_kg.text)!,
      date: _date,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.progressWeightSheetTitle,
              style: context.textStyles.titleLarge,
            ),
            AppSpacing.gapLg,
            AppTextField(
              controller: _kg,
              label: l10n.progressWeightField,
              suffixText: l10n.unitKg,
              prefixIcon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,3}([.,]\d?)?'),
                ),
              ],
              textInputAction: TextInputAction.done,
              validator: _validate,
              onSubmitted: (_) => _submit(),
            ),
            AppSpacing.gapLg,
            Text(l10n.progressDateField, style: context.textStyles.labelLarge),
            AppSpacing.gapSm,
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(AppFormat.date(context, _date)),
            ),
            if (widget.withNote) ...[
              AppSpacing.gapLg,
              AppTextField(
                controller: _note,
                label: l10n.weightNoteField,
                hint: l10n.weightNoteHint,
                prefixIcon: Icons.notes_rounded,
                textInputAction: TextInputAction.done,
              ),
            ],
            AppSpacing.gapXl,
            FilledButton(onPressed: _submit, child: Text(l10n.actionSave)),
          ],
          ),
        ),
      ),
    );
  }
}
