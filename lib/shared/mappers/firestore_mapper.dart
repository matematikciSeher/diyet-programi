import '../../core/utils/json_utils.dart';
import '../services/database/document_database.dart';

/// Firestore ile yerel JSON arasında tarih/enum güvenli dönüşüm.
///
/// `cloud_firestore.Timestamp` bu sınıfa bağlanmaz; Timestamp nesneleri
/// [FirestoreDocumentDatabase] sınırında DateTime'a çevrilir. Böylece
/// mapper birim testlerinde Firebase gerektirmez.
abstract final class FirestoreMapper {
  static final _isoDate = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}',
  );

  /// Firestore'dan (veya Timestamp benzeri map'ten) gelen veriyi yerel
  /// modellerin beklediği ISO-8601 / düz JSON'a çevirir.
  static JsonMap decode(JsonMap data) =>
      _walk(data, _decodeValue) as JsonMap;

  /// Yerel JSON'u Firestore'a yazılmadan önce dolaşır; ISO tarih
  /// dizgelerini [DateTime] yapar. Asıl Timestamp dönüşümü remote
  /// adaptördedir.
  static JsonMap encode(JsonMap data) =>
      _walk(data, _encodeValue) as JsonMap;

  /// Last-write-wins için belgedeki en yeni zaman damgası.
  static DateTime? writtenAt(JsonMap data) =>
      JsonUtils.readDate(data['updatedAt']) ??
      JsonUtils.readDate(data['deviceUpdatedAt']) ??
      JsonUtils.readDate(data['createdAt']) ??
      JsonUtils.readDate(data['recordedAt']) ??
      JsonUtils.readDate(data['loggedAt']);

  static Object? _walk(Object? value, Object? Function(Object?) convert) {
    final converted = convert(value);
    if (converted is Map) {
      return <String, dynamic>{
        for (final entry in converted.entries)
          '${entry.key}': _walk(entry.value, convert),
      };
    }
    if (converted is List) {
      return [for (final item in converted) _walk(item, convert)];
    }
    return converted;
  }

  static Object? _decodeValue(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    final fromStamp = JsonUtils.readDate(value);
    if (fromStamp != null && value is Map) {
      return fromStamp.toIso8601String();
    }
    return value;
  }

  static Object? _encodeValue(Object? value) {
    if (value is DateTime) return value;
    if (value is String && _isoDate.hasMatch(value)) {
      return DateTime.tryParse(value) ?? value;
    }
    return value;
  }
}

/// Çakışmada daha yeni [updatedAt] / [deviceUpdatedAt] kazanır.
abstract final class LastWriteWins {
  static JsonMap resolve(JsonMap local, JsonMap remote) {
    final localAt = FirestoreMapper.writtenAt(local);
    final remoteAt = FirestoreMapper.writtenAt(remote);
    if (localAt == null) return remote;
    if (remoteAt == null) return local;
    return remoteAt.isAfter(localAt) ? remote : local;
  }
}
