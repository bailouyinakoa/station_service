// ignore_for_file: file_names

import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

class DeviceId {
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String? deviceId = "";
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? "unknown";
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      deviceId = "${linuxInfo.machineId}";
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      deviceId = macInfo.systemGUID;
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceId = windowsInfo.deviceId;
    }

    return deviceId ?? "unknown";
  }

  static Future<String> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String? deviceId = "";
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId =
          "brach=${androidInfo.brand}-model=${androidInfo.model}-version=${androidInfo.version} -id=${androidInfo.id}";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? "unknown";
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      deviceId =
          "name=${linuxInfo.name}-id=${linuxInfo.machineId}-version=${linuxInfo.version}";
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      deviceId = macInfo.systemGUID;
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceId =
          "model=${windowsInfo.computerName}-version=${windowsInfo.majorVersion}-id=${windowsInfo.deviceId}";
    }

    return deviceId ?? "unknown";
  }
}
