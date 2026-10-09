import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../domain/models/portion_selection.dart';
import '../food_format.dart';

/// Arama/listelerde bir yiyecek: isim, porsiyon, kalori ve makrolar.
/// [onQuickAdd] verilirse tek dokunuşla ekleme butonu gösterilir.
class FoodListTile extends StatelessWidget {
  const FoodListTile({
    super.key,
    required this.food,
    required this.selection,
    required this.nutrition,
    required this.onTap,
    this.onQuickAdd,
    this.trailing,
  });

  final Food food;
  final PortionSelection selection;
  final NutritionFacts nutrition;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brand = food.brand;
    final muted = context.textStyles.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.sm,
      ),
      leading: _FoodAvatar(food: food),
      title: Text.rich(
        TextSpan(
          text: food.name,
          children: [
            if (brand != null) TextSpan(text: ' · $brand', style: muted),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${FoodFormat.selection(context, food, selection)}'
            ' · ${FoodFormat.kcal(context, nutrition.calories)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            FoodFormat.macros(
              context,
              nutrition.proteinG,
              nutrition.carbsG,
              nutrition.fatG,
            ),
            style: muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing:
          trailing ??
          (onQuickAdd == null
              ? null
              : IconButton.filledTonal(
                  onPressed: onQuickAdd,
                  tooltip: l10n.foodQuickAdd(food.name),
                  icon: const Icon(Icons.add_rounded),
                )),
    );
  }
}

class _FoodAvatar extends StatelessWidget {
  const _FoodAvatar({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final url = food.imageUrl;
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        backgroundColor: context.colors.secondaryContainer,
        foregroundColor: context.colors.onSecondaryContainer,
        child: Icon(food.source.icon, size: AppSizes.iconSm + 2),
      );
    }
    return CircleAvatar(
      backgroundColor: context.colors.secondaryContainer,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, _) {},
      child: const SizedBox.shrink(),
    );
  }
}
