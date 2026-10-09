import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';

/// Konum: `users/{uid}/weight_entries/{id}`.
class WeightEntry extends Equatable {
  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.recordedAt,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? recordedAt,
       updatedAt = updatedAt ?? recordedAt;

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    final recordedAt = JsonUtils.readDateOr(
      json['recordedAt'] ?? json['date'],
      DateTime.now(),
    );
    return WeightEntry(
      id: JsonUtils.readString(json['id']),
      weightKg: JsonUtils.readDouble(json['weightKg'] ?? json['weight']),
      recordedAt: recordedAt,
      note: json['note'] as String?,
      createdAt: JsonUtils.readDate(json['createdAt']) ?? recordedAt,
      updatedAt: JsonUtils.readDate(json['updatedAt']) ?? recordedAt,
    );
  }

  final String id;
  final double weightKg;

  /// Kayıt tarihi (kullanıcının seçtiği gün).
  final DateTime recordedAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'weightKg': weightKg,
    'recordedAt': recordedAt.toIso8601String(),
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    weightKg,
    recordedAt,
    note,
    createdAt,
    updatedAt,
  ];
}
