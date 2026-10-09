import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../data/datasources/recipe_images.dart';
import '../../domain/models/recipe_category.dart';
import '../recipe_labels.dart';

/// Tarif görseli; görsel yoksa kategori simgeli renkli alan gösterilir.
class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.recipe, this.iconSize = 40});

  final Recipe recipe;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final category = RecipeCategory.of(recipe).firstOrNull;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.tertiaryContainer],
        ),
      ),
      child: Center(
        child: Icon(
          category?.icon ?? Icons.restaurant_rounded,
          size: iconSize,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
    final url = RecipeImages.urlFor(recipe);
    return ExcludeSemantics(
      child: url == null || url.isEmpty
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

String recipeMacroLine(BuildContext context, Recipe recipe) {
  final l10n = context.l10n;
  final n = recipe.nutritionPerServing;
  return l10n.macroSummaryShort(
    AppFormat.integer(context, n.proteinG),
    AppFormat.integer(context, n.carbsG),
    AppFormat.integer(context, n.fatG),
  );
}

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.favorite,
    required this.onTap,
  });

  final Recipe recipe;
  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final variant = context.colors.onSurfaceVariant;
    final minutes = recipe.totalMinutes;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RecipeImage(recipe: recipe),
                  if (favorite)
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      end: AppSpacing.sm,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: context.colors.error,
                        semanticLabel: l10n.recipeFavorite,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
                AppSpacing.gapXs,
                Text(
                  l10n.kcalValue(
                    AppFormat.integer(
                      context,
                      recipe.nutritionPerServing.calories,
                    ),
                  ),
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.primary,
                  ),
                ),
                Text(
                  recipeMacroLine(context, recipe),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: variant,
                  ),
                ),
                if (minutes > 0) ...[
                  AppSpacing.gapXs,
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: AppSizes.iconSm,
                        color: variant,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        l10n.recipeMinutes(minutes),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: variant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
