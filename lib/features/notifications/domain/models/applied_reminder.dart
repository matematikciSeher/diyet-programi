import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';

/// İşletim sistemine yazılmış bir hatırlatmanın parmak izi.
/// Saat veya metin değişmediyse bildirim yeniden kurulmaz.
class AppliedReminder extends Equatable {
  const AppliedReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.repeat,
    this.minutes,
    this.weekday,
    this.at,
  });

  factory AppliedReminder.fromJson(Map<String, dynamic> json) =>
      AppliedReminder(
        id: JsonUtils.readInt(json['id']),
        title: JsonUtils.readString(json['title']),
        body: JsonUtils.readString(json['body']),
        payload: JsonUtils.readString(json['payload']),
        repeat: JsonUtils.readString(json['repeat']),
        minutes: JsonUtils.readIntOrNull(json['minutes']),
        weekday: JsonUtils.readIntOrNull(json['weekday']),
        at: JsonUtils.readStringOrNull(json['at']),
      );

  final int id;
  final String title;
  final String body;
  final String payload;
  final String repeat;
  final int? minutes;
  final int? weekday;
  final String? at;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'payload': payload,
    'repeat': repeat,
    'minutes': minutes,
    'weekday': weekday,
    'at': at,
  };

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    payload,
    repeat,
    minutes,
    weekday,
    at,
  ];
}
