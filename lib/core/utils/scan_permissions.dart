import 'package:permission_handler/permission_handler.dart';

class ScanPermissions {
  static Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> ensureGallery() async {
    if (await _photosGranted()) return true;

    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;

    final photos = await Permission.photos.request();
    return photos.isGranted;
  }

  static Future<bool> _photosGranted() async {
    final photos = await Permission.photos.status;
    return photos.isGranted;
  }
}
