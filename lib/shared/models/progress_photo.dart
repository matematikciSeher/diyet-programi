import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';

/// Meta veri: `users/{uid}/progress_photos/{id}`.
/// Görsel dosyası [storagePath] altında dosya depolamada tutulur.
class ProgressPhoto extends Equatable {
  const ProgressPhoto({
    required this.id,
    required this.storagePath,
    required this.url,
    required this.takenAt,
    this.weightKg,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) => ProgressPhoto(
    id: JsonUtils.readString(json['id']),
    storagePath: JsonUtils.readString(json['storagePath']),
    url: JsonUtils.readString(json['url']),
    takenAt: JsonUtils.readDateOr(json['takenAt'], DateTime.now()),
    weightKg: JsonUtils.readDoubleOrNull(json['weightKg']),
  );

  final String id;
  final String storagePath;
  final String url;
  final DateTime takenAt;

  /// Fotoğraf çekildiği sıradaki güncel kilo; karşılaştırmada gösterilir.
  final double? weightKg;

  Map<String, dynamic> toJson() => {
    'id': id,
    'storagePath': storagePath,
    'url': url,
    'takenAt': takenAt.toIso8601String(),
    'weightKg': weightKg,
  };

  @override
  List<Object?> get props => [id, storagePath, url, takenAt, weightKg];
}
