import '../../core/errors/app_exception.dart';
import '../services/database/document_database.dart';

/// Oturum açmış kullanıcıya ait verilerle (`users/{uid}/...`) çalışan
/// repository'ler için taban sınıf.
abstract base class UserScopedRepository {
  const UserScopedRepository(this.db, this.uid);

  final DocumentDatabase db;
  final String? uid;

  String requireUid() {
    final id = uid;
    if (id == null) throw const AuthException('not_authenticated');
    return id;
  }
}
