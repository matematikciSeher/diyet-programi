import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';

/// Vücut ölçümleri (cm) ve yağ oranı (%).
/// Konum: `users/{uid}/measurements/{id}`.
class BodyMeasurement extends Equatable {
  const BodyMeasurement({
    required this.id,
    required this.recordedAt,
    this.waistCm,
    this.hipCm,
    this.chestCm,
    this.neckCm,
    this.armCm,
    this.thighCm,
    this.bodyFatPercent,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: JsonUtils.readString(json['id']),
      recordedAt: JsonUtils.readDateOr(json['recordedAt'], DateTime.now()),
      waistCm: JsonUtils.readDoubleOrNull(json['waistCm']),
      hipCm: JsonUtils.readDoubleOrNull(json['hipCm']),
      chestCm: JsonUtils.readDoubleOrNull(json['chestCm']),
      neckCm: JsonUtils.readDoubleOrNull(json['neckCm']),
      armCm: JsonUtils.readDoubleOrNull(json['armCm']),
      thighCm: JsonUtils.readDoubleOrNull(json['thighCm']),
      bodyFatPercent: JsonUtils.readDoubleOrNull(json['bodyFatPercent']),
    );
  }

  final String id;
  final DateTime recordedAt;
  final double? waistCm;
  final double? hipCm;
  final double? chestCm;
  final double? neckCm;
  final double? armCm;
  final double? thighCm;
  final double? bodyFatPercent;

  Map<String, dynamic> toJson() => {
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'waistCm': waistCm,
    'hipCm': hipCm,
    'chestCm': chestCm,
    'neckCm': neckCm,
    'armCm': armCm,
    'thighCm': thighCm,
    'bodyFatPercent': bodyFatPercent,
  };

  @override
  List<Object?> get props => [
    id,
    recordedAt,
    waistCm,
    hipCm,
    chestCm,
    neckCm,
    armCm,
    thighCm,
    bodyFatPercent,
  ];
}
