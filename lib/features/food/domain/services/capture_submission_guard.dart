/// Aynı onayın iki kez günlüğe yazılmasını engeller.
/// Başarısız denemede kimlik serbest bırakılır; başarılı kayıt kalır.
class CaptureSubmissionGuard {
  final Set<String> _done = {};
  String? _inFlight;

  bool claim(String id) {
    if (id.isEmpty || _done.contains(id) || _inFlight == id) return false;
    _inFlight = id;
    return true;
  }

  void succeed(String id) {
    _done.add(id);
    if (_inFlight == id) _inFlight = null;
  }

  void release(String id) {
    if (_inFlight == id) _inFlight = null;
  }
}
