import '../../models/food.dart';

/// Barkoddan ürün tanıma (Open Food Facts benzeri servis).
/// Kamera ile tarama `mobile_scanner` ile presentation katmanında yapılır;
/// bu servis yalnızca barkod -> ürün eşlemesini üstlenir.
abstract interface class BarcodeLookupService {
  Future<Food?> lookup(String barcode);
}

class EmptyBarcodeLookupService implements BarcodeLookupService {
  const EmptyBarcodeLookupService();

  @override
  Future<Food?> lookup(String barcode) async => null;
}
