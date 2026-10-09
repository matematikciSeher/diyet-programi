import 'dart:io';

/// Kamera/galeri geçici dosyasını siler.
///
/// Fotoğraf günlüğe, Firestore'a veya Firebase Storage'a yazılmaz. İşlem
/// bitince (veya vazgeçilince) yalnızca bellek içi baytlar kalır; onlar da
/// ekran kapanınca bırakılır.
Future<void> deleteTempCaptureFile(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } on Object {
    // Silinemeyen geçici dosya yine de kalıcı kayda dönüştürülmez.
  }
}
