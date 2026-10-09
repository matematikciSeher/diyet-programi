import '../../../../core/utils/app_logger.dart';

/// Barkod lookup izi. [AppLogger.debug] release'de yazılmaz.
abstract final class BarcodeLookupLog {
  static void write({
    required String barcode,
    required String source,
    String? url,
    Object? httpStatus,
    Object? offStatus,
    required bool productFound,
    bool? mapped,
    String? productName,
    String? code,
  }) {
    final mappedPart = mapped == null ? '' : ' mapped=$mapped';
    final namePart = productName == null || productName.isEmpty
        ? ''
        : ' productName=$productName';
    final codePart = code == null || code.isEmpty ? '' : ' code=$code';
    AppLogger.debug(
      'Barcode lookup: barcode=$barcode source=$source url=$url '
      'httpStatus=$httpStatus offStatus=$offStatus '
      'productFound=$productFound$mappedPart$namePart$codePart',
    );
  }
}
