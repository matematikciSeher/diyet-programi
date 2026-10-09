import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/presentation/enum_labels.dart';

/// Kahvaltı / öğle / akşam / atıştırmalık seçimi.
class MealTypeSelector extends StatelessWidget {
  const MealTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.scrollable = false,
  });

  final MealType value;
  final ValueChanged<MealType> onChanged;

  /// Dar alanlarda tek satırda yatay kaydırılır.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = [
      for (final type in MealType.values)
        ChoiceChip(
          avatar: Icon(type.icon, size: AppSizes.iconSm),
          label: Text(type.label(l10n)),
          selected: type == value,
          showCheckmark: false,
          onSelected: (_) => onChanged(type),
        ),
    ];
    if (!scrollable) {
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.page,
      child: Row(
        children: [
          for (final (i, chip) in chips.indexed) ...[
            if (i > 0) AppSpacing.gapSm,
            chip,
          ],
        ],
      ),
    );
  }
}
