import 'dart:async';
//import 'dart:isolate';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:background_locator_2/auto_stop_handler.dart';
import 'package:background_locator_2/background_locator.dart';
//import 'package:background_locator_2/callback_dispatcher.dart';
//import 'package:background_locator_2/keys.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
//import 'package:background_locator_2/utils/settings_util.dart';
//import 'dart:developer' as developer;

Future<void> initPlatformState() async {
  await BackgroundLocator.initialize();
}

class LocationCallbackHandler {
  static const String isolateName = "LocatorIsolate";

  @pragma('vm:entry-point')
  static Future<void> _initCallback(Map<dynamic, dynamic> params) async {
    print('initCallback');
  }

  @pragma('vm:entry-point')
  static Future<void> _disposeCallback() async {
    print('disposeCallback');
  }

  @pragma('vm:entry-point')
  static Future<void> _callback(LocationDto locationDto) async {
    User user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('locations').doc(user.uid).set({
      'latitude': locationDto.latitude,
      'longitude': locationDto.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });//  print('Location: ${locationDto.latitude}, ${locationDto.longitude}');
  }

  static void startLocationService() {
//    developer.log('=== startLocationService');
    BackgroundLocator.registerLocationUpdate(_callback,
        initCallback: _initCallback,
        disposeCallback: _disposeCallback,
        autoStop: false,
        iosSettings: const IOSSettings(
            accuracy: LocationAccuracy.NAVIGATION, distanceFilter: 10),
        androidSettings: const AndroidSettings(
          accuracy: LocationAccuracy.NAVIGATION,
          interval: 5,
          distanceFilter: 10,
        ));
  }
}