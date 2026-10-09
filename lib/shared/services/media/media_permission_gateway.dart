import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum MediaAccess { granted, denied, permanentlyDenied }

/// Kamera, galeri ve mikrofon izni. Uygulama açılışında çağrılmaz.
abstract interface class MediaPermissionGateway {
  Future<MediaAccess> requestCamera();
  Future<MediaAccess> requestPhotos();
  Future<MediaAccess> requestMicrophone();
  Future<bool> openSettings();
}

class PermissionHandlerGateway implements MediaPermissionGateway {
  const PermissionHandlerGateway();

  @override
  Future<MediaAccess> requestCamera() => _request(Permission.camera);

  @override
  Future<MediaAccess> requestMicrophone() => _request(Permission.microphone);

  /// Android fotoğraf seçicisi çoğu sürümde depolama izni istemez.
  /// iOS'ta fotoğraf arşivi izni, kullanıcı galeriyi açınca istenir.
  @override
  Future<MediaAccess> requestPhotos() async {
    if (!Platform.isIOS && !Platform.isMacOS) return MediaAccess.granted;
    return _request(Permission.photos);
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  Future<MediaAccess> _request(Permission permission) async {
    final current = await permission.status;
    if (current.isGranted || current.isLimited) return MediaAccess.granted;
    if (current.isPermanentlyDenied || current.isRestricted) {
      return MediaAccess.permanentlyDenied;
    }
    final next = await permission.request();
    if (next.isGranted || next.isLimited) return MediaAccess.granted;
    if (next.isPermanentlyDenied || next.isRestricted) {
      return MediaAccess.permanentlyDenied;
    }
    return MediaAccess.denied;
  }
}
