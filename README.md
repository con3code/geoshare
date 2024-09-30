# Geoshare

Geolocation share app.

## Getting Started

This project is a Flutter application.
It is an app for sharing location information. works on iOS and Android.

It uses GoogleMap and Firebase services; API keys for those services are required to run the app.

- Google Maps Platform
- Firebase Authentication
- Firebase Firestore


### Google Maps Platform API

The API key for Google Maps Platform is:
For Android
/geoshare/android/secret.properties
For iOS
/geoshare/ios/Runner/Env.swift
The API key is set in


### Firebase API

For Firebase, install the Firebase CLI in your Flutter project and configure as needed in Flutter The following documentation is helpful.
https://firebase.google.com/docs/cli
https://firebase.google.com/docs/flutter/setup

Here is the information needed to install the google_sign_in module
https://pub.dev/packages/google_sign_in_ios#ios-integration

For Android, you need to register the SHA-1 of the device's signing certificate on the Firebase side.
https://developers.google.com/android/guides/client-auth


### etc.

Also, for Android,
You need to set the SDK directory in /android/local.properties.


=== Japanese

位置情報を共有するためのアプリです｡iOSとAndroidで動作します｡

GoogleMapとFirebaseのサービスを利用しています｡それらのサービスのAPIキーを用意することでアプリを動作させることができます｡

- Google Maps Platform
- Firebase Authentication
- Firebase Firestore


### Google Maps Platform API

Google Maps PlatformのAPIキーは：
Androidの場合
/geoshare/android/secret.properties
iOSの場合
/geoshare/ios/Runner/Env.swift
に設定します｡


### Firebase API

Firebaseは、FlutterプロジェクトにFirebase CLIをインストールして，Flutterで必要な設定をしてください｡以下のドキュメントが参考になります｡
https://firebase.google.com/docs/cli
https://firebase.google.com/docs/flutter/setup

google_sign_inモジュールを導入するために必要な情報はこちら
https://pub.dev/packages/google_sign_in_ios#ios-integration

Androidの場合は端末の署名証明書のSHA-1をFirebase側に登録する必要があります｡
https://developers.google.com/android/guides/client-auth


### その他

また、Androidの場合は、
/android/local.propertiesにSDKのディレクトリを設定する必要があります｡


## Flutter

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
