import 'dart:typed_data';

/// Dosya depolama (profil fotoğrafı, yemek fotoğrafı, ilerleme fotoğrafı).
/// Hedef implementasyon: `FirebaseFileStorageService` (firebase_storage).
abstract interface class FileStorageService {
  /// Dosyayı yükler ve indirme URL'sini döndürür.
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    String? contentType,
  });

  /// Dosya yoksa `null` döner.
  Future<Uint8List?> download(String path);

  Future<void> delete(String path);
}

/// Firebase bağlanana kadar dosyaları bellekte tutar; uygulama
/// kapanınca silinir.
class InMemoryFileStorageService implements FileStorageService {
  final Map<String, Uint8List> _files = {};

  @override
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    _files[path] = bytes;
    return 'memory://$path';
  }

  @override
  Future<Uint8List?> download(String path) async => _files[path];

  @override
  Future<void> delete(String path) async => _files.remove(path);
}
