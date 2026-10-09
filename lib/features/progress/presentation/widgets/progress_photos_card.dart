import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/models/progress_photo.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../progress_labels.dart';
import '../providers/progress_providers.dart';

/// İlk ve son fotoğrafın karşılaştırması ile tüm fotoğrafların şeridi.
class ProgressPhotosCard extends StatelessWidget {
  const ProgressPhotosCard({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onOpen,
  });

  /// En yeni önce.
  final List<ProgressPhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<ProgressPhoto> onOpen;

  static const _thumbSize = 88.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.photo_library_outlined,
            title: l10n.progressPhotosTitle,
            color: context.colors.secondary,
            trailing: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.progressAddPhoto),
            ),
          ),
          AppSpacing.gapMd,
          if (photos.isEmpty)
            Text(
              l10n.progressPhotosEmpty,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          else ...[
            if (photos.length >= 2) ...[
              Row(
                children: [
                  Expanded(
                    child: _ComparisonTile(
                      label: l10n.progressPhotoFirst,
                      photo: photos.last,
                      onTap: () => onOpen(photos.last),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: _ComparisonTile(
                      label: l10n.progressPhotoLatest,
                      photo: photos.first,
                      onTap: () => onOpen(photos.first),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,
            ],
            SizedBox(
              height: _thumbSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, i) {
                  final photo = photos[i];
                  return Semantics(
                    button: true,
                    label: AppFormat.date(context, photo.takenAt),
                    child: InkWell(
                      onTap: () => onOpen(photo),
                      borderRadius: AppRadius.mdAll,
                      child: ClipRRect(
                        borderRadius: AppRadius.mdAll,
                        child: SizedBox.square(
                          dimension: _thumbSize,
                          child: ProgressPhotoImage(photo: photo),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonTile extends StatelessWidget {
  const _ComparisonTile({
    required this.label,
    required this.photo,
    required this.onTap,
  });

  final String label;
  final ProgressPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weight = photo.weightKg;
    final caption = [
      AppFormat.date(context, photo.takenAt),
      if (weight != null) ProgressFormat.kg(context, weight),
    ].join(' · ');
    return Semantics(
      button: true,
      label: '$label, $caption',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ProgressPhotoImage(photo: photo),
              ),
            ),
            AppSpacing.gapXs,
            Text(label, style: context.textStyles.labelLarge),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fotoğrafı dosya depolamadan yükleyip gösterir.
class ProgressPhotoImage extends ConsumerWidget {
  const ProgressPhotoImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
  });

  final ProgressPhoto photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(progressPhotoImageProvider(photo));
    final placeholder = ColoredBox(
      color: context.colors.surfaceContainerHighest,
      child: Center(
        child: image.isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.broken_image_outlined,
                semanticLabel: context.l10n.progressPhotoUnavailable,
                color: context.colors.onSurfaceVariant,
              ),
      ),
    );
    final bytes = image.value;
    if (bytes == null) return placeholder;
    return Image.memory(
      bytes,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
