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
      int sdkInt = androidInfo.version.sdkInt;

      // Android 13+ (SDK 33+)
      if (sdkInt >= 33) {
        await requestAndroid13Permissions();
      }
      // Android 11-12 (SDK 30-32)
      else if (sdkInt >= 30) {
        await requestAndroid11Permissions();
      }
      // Android 10 and below
      else {
        await requestOldAndroidPermissions();
      }
    } else {
      // Handle iOS or other platforms if needed
    }
  }

  Future<void> requestAndroid13Permissions() async {
    PermissionStatus audioStatus = await Permission.audio.request();
    PermissionStatus mediaStatus = await Permission.photos.request();
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (audioStatus.isGranted && mediaStatus.isGranted && status.isGranted) {
      goToConfigureMusicPage();
    } else {
      handlePermissionDenial();
    }
  }

  Future<void> requestAndroid11Permissions() async {
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      goToConfigureMusicPage();
    } else {
      handlePermissionDenial();
    }
  }

  Future<void> requestOldAndroidPermissions() async {
    PermissionStatus storageStatus = await Permission.storage.request();

    if (storageStatus.isGranted) {
      goToConfigureMusicPage();
    } else {
      handlePermissionDenial();
    }
  }

  void handlePermissionDenial() {
    setState(() {
      showText = true;
    });
  }

  void goToConfigureMusicPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfigureMusicPage(firstConfigure: true),
      ),
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

              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary), // Button background color
              child: Text(
                "Request Permissions",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
            Visibility(
              visible: showText,
              child: const Text(
                "Access to your files is needed to pull in your music library. "
                "Please hit the button above to give the needed permissions.",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
