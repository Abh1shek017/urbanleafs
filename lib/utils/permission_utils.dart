import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  // Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      openAppSettings(); // Redirect user to app settings
      return false;
    }

    return false;
  }

  // Request storage permission (Android only)
  static Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    return false;
  }

  // Request location permission
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    return false;
  }

  // Check if permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  // Open app settings manually
  static void openAppSettingsDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => AlertDialog(
        title: Text("Permissions Required"),
        content: Text("Please enable required permissions from app settings."),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }
}