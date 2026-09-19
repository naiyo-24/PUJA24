import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

class PermissionHelper {
  /// Requests location permission after showing a prominent disclosure dialog if the permission is currently denied.
  static Future<LocationPermission> requestLocationPermission(BuildContext context, {required String rationale}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Show prominent disclosure before the OS prompt
      final bool? shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.charcoal : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.pujaRed, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location Access',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              rationale,
              style: TextStyle(
                fontSize: 15, 
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Now', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pujaRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      );

      if (shouldRequest == true) {
        permission = await Geolocator.requestPermission();
      }
    }
    
    return permission;
  }

  /// Requests photos permission after showing a prominent disclosure dialog if the permission is currently denied.
  static Future<PermissionStatus> requestPhotoPermission(BuildContext context, {required String rationale}) async {
    PermissionStatus status = await Permission.photos.status;
    
    if (status.isDenied || status.isRestricted) {
      final bool? shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.charcoal : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.photo_library_rounded, color: AppColors.pujaRed, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Photos Access',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              rationale,
              style: TextStyle(
                fontSize: 15, 
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Now', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pujaRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      );

      if (shouldRequest == true) {
        status = await Permission.photos.request();
      }
    }
    
    return status;
  }

  /// Requests camera permission after showing a prominent disclosure dialog if the permission is currently denied.
  static Future<PermissionStatus> requestCameraPermission(BuildContext context, {required String rationale}) async {
    PermissionStatus status = await Permission.camera.status;
    
    if (status.isDenied || status.isRestricted) {
      final bool? shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.charcoal : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.camera_alt_rounded, color: AppColors.pujaRed, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Camera Access',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              rationale,
              style: TextStyle(
                fontSize: 15, 
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Now', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pujaRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      );

      if (shouldRequest == true) {
        status = await Permission.camera.request();
      }
    }
    
    return status;
  }
}
