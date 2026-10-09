import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';

/// Konum: `users/{uid}/water_logs/{id}`.
class WaterLog extends Equatable {
  const WaterLog({
    required this.id,
    required this.dayKey,
    required this.amountMl,
    required this.loggedAt,
  });

  factory WaterLog.fromJson(Map<String, dynamic> json) => WaterLog(
    id: JsonUtils.readString(json['id']),
    dayKey: JsonUtils.readString(json['dayKey']),
    amountMl: JsonUtils.readInt(json['amountMl']),
    loggedAt: JsonUtils.readDateOr(json['loggedAt'], DateTime.now()),
  );

  final String id;
  final String dayKey;
  final int amountMl;
  final DateTime loggedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayKey': dayKey,
    'amountMl': amountMl,
    'loggedAt': loggedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, dayKey, amountMl, loggedAt];
}
