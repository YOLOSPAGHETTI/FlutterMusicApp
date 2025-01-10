import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:music_app/pages/configure_music_page.dart';
import 'package:permission_handler/permission_handler.dart';

class CheckPermissionsPage extends StatefulWidget {
  const CheckPermissionsPage({super.key});

  @override
  State<CheckPermissionsPage> createState() => _CheckPermissionsPageState();
}

class _CheckPermissionsPageState extends State<CheckPermissionsPage> {
  bool showText = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // For Android 13+
        PermissionStatus status = await Permission.audio.request();
        addressPermissionStatus(status);
        status = await Permission.photos.request();
        addressPermissionStatus(status);
        if (await Permission.audio.isGranted &&
            await Permission.photos.isGranted) {
          goToConfigureMusicPage();
        }
      } else if (androidInfo.version.sdkInt >= 30) {
        // For Android 11+
        PermissionStatus status =
            await Permission.manageExternalStorage.request();
        addressPermissionStatus(status);
        if (await Permission.manageExternalStorage.isGranted) {
          goToConfigureMusicPage();
        }
      } else {
        // For older Android versions
        PermissionStatus status = await Permission.storage.request();
        addressPermissionStatus(status);
        if (await Permission.storage.isGranted) {
          goToConfigureMusicPage();
        }
      }
    }
  }

  Future<void> addressPermissionStatus(PermissionStatus status) async {
    if (status.isPermanentlyDenied) {
      showText = true;
      // Open app settings for manual permission granting
      await openAppSettings();
    } else if (status.isDenied) {
      // Inform the user why the permission is necessary
      showText = true;
    }
  }

  void goToConfigureMusicPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const ConfigureMusicPage(
                firstConfigure: true,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(title: const Text("Allow File Permissions")),
        body: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(25),
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: requestPermissions,
                  child: const Text("Request Permissions")),
              Visibility(
                  visible: showText,
                  child: const Text(
                      "Access to your files is needed to pull in your music library. Please hit the button above to give the needed permissions"))
            ],
          ),
        ));
  }
}
