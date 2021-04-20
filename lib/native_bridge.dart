import 'dart:async';

import 'package:flutter/services.dart';

/// Inspired from: https://flutter.io/docs/development/platform-integration/platform-channels
/// Read more: https://proandroiddev.com/communication-between-flutter-and-native-modules-9b52c6a72dd2
class NativeBridge {
  static const platform =
      const MethodChannel('com.example.MethodChannelDemo/native_channel');

  static const String SUCCESS_RESULT = "1";
  static const String FAILURE_RESULT = "0";

  static bool __isAppInForeground;
  static bool get _isAppInForeground => __isAppInForeground;
  static bool get isAppInForeground => _isAppInForeground ?? true;
  static set _isAppInForeground(bool isAppInForeground) {
    __isAppInForeground = isAppInForeground;
    if (isAppInForeground) {
//      LocalBroadcast.notifyEvent(LocalBroadcast.Key_ON_APPLICATION_BACK_FROM_BACKGROUND_TO_FOREGROUND);
    } else {
//      LocalBroadcast.notifyEvent(LocalBroadcast.Key_ON_APPLICATION_ENTERED_BACKGROUND);
    }
  }

  static Future<dynamic> init() async {
    _isAppInForeground = true;
    platform.setMethodCallHandler((MethodCall call) {
      //Utils.debugToast('NativeBridge: "got method call from native host: ${call.method}(${call.arguments})"');

      dynamic result = FAILURE_RESULT;
      switch (call.method) {
        case 'application_entered_background':
          _isAppInForeground = false;
          result = NativeBridge.SUCCESS_RESULT;
          break;
        case 'flutter_is_presented':
        case 'application_entered_foreground':
          _isAppInForeground = true;
          result = NativeBridge.SUCCESS_RESULT;
          break;
        default:
//          Utils.debugToast("Unhandled native bridge call named: '${call.method}'");
//          AppLogger.error("Unhandled native bridge call named: '${call.method}'");
          result = NativeBridge.FAILURE_RESULT;
      }

      return new Future.value(result);
    });
  }

  static Future<String> invokeNativeMethod(String methodName,
      [dynamic arguments]) async {
    String result;
    try {
      if (arguments == null) {
        result = await platform.invokeMethod(methodName);
      } else {
        result = await platform.invokeMethod(methodName, arguments);
      }
//      AppLogger.log("Native method '$methodName' returned result: $result", withStackTrace: false);
    } on PlatformException catch (e) {
      String errorMessageString =
          "Failed to run native method, error: '${e.message}'.";
      print(errorMessageString);
//      Utils.debugToast(errorMessageString);
    }

    return result;
  }

  static Future<String> saveToSecuredData({String key, String value}) async {
    String result = await NativeBridge.invokeNativeMethod(
        "save_in_secured_storage", {key: value});
    return result;
  }

  static Future<String> loadFromSecuredData(
      {String key, dynamic defaultValue}) async {
    String result = await NativeBridge.invokeNativeMethod(
        "load_from_secured_storage", {key: defaultValue});
    return result ?? defaultValue;
  }
}
