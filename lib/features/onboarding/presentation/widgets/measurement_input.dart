import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Yaş, boy, kilo gibi tek bir sayısal değer için büyük, ortalanmış giriş.
class MeasurementInput extends StatefulWidget {
  const MeasurementInput({
    super.key,
    required this.unit,
    required this.onChanged,
    this.initialValue,
    this.allowDecimal = false,
    this.maxIntegerDigits = 3,
    this.onSubmitted,
    this.errorText,
    this.helperText,
  });

  final num? initialValue;
  final String unit;
  final bool allowDecimal;
  final int maxIntegerDigits;
  final ValueChanged<num?> onChanged;
  final VoidCallback? onSubmitted;
  final String? errorText;
  final String? helperText;

  static num? parse(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty || normalized == '.') return null;
    return num.tryParse(normalized);
  }

  @override
  State<MeasurementInput> createState() => _MeasurementInputState();
}

class _MeasurementInputState extends State<MeasurementInput> {
  late final TextEditingController _controller;
  late final RegExp _pattern;

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    final text = v == null
        ? ''
        : (v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1));
    _controller = TextEditingController(text: text);
    _pattern = widget.allowDecimal
        ? RegExp('^\\d{0,${widget.maxIntegerDigits}}([.,]\\d?)?\$')
        : RegExp('^\\d{0,${widget.maxIntegerDigits}}\$');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.numberWithOptions(
            decimal: widget.allowDecimal,
          ),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            TextInputFormatter.withFunction(
              (oldValue, newValue) =>
                  _pattern.hasMatch(newValue.text) ? newValue : oldValue,
            ),
          ],
          style: context.textStyles.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: hasError ? colors.error : colors.onSurface,
          ),
          onChanged: (text) => widget.onChanged(MeasurementInput.parse(text)),
          onSubmitted: (_) => widget.onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: widget.unit,
            suffixStyle: context.textStyles.titleLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            errorText: widget.errorText,
            errorMaxLines: 3,
          ),
        ),
        if (widget.helperText != null && !hasError) ...[
          AppSpacing.gapSm,
          Text(
            widget.helperText!,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
