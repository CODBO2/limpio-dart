import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

class InvoiceImageCropper {
  static Future<XFile?> cropInvoiceImage(
    BuildContext context,
    XFile source,
  ) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: source.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar factura',
          toolbarColor: AppColors.ink,
          toolbarWidgetColor: Colors.white,
          statusBarLight: false,
          navBarLight: false,
          backgroundColor: AppColors.ink,
          activeControlsWidgetColor: Colors.white,
          cropFrameColor: Colors.white,
          cropGridColor: Colors.white54,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Recortar factura',
          doneButtonTitle: 'Listo',
          cancelButtonTitle: 'Cancelar',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (cropped == null) return null;
    return XFile(cropped.path);
  }
}
