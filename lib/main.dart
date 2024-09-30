import 'dart:io';
import 'dart:async';
//import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'get_background_location.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:google_sign_in/google_sign_in.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
  LocationCallbackHandler.startLocationService();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return MaterialApp(
        title: 'GeoShare',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
          primarySwatch: Colors.blue,
        ),
        home: const AuthenticationWrapper(),
        debugShowCheckedModeBanner: false,
      );
    } else if (Platform.isIOS) {
      return const CupertinoApp(
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: AuthenticationWrapper(),
        debugShowCheckedModeBanner: false,
      );
    } else {
      return Container();
    }
  }
}

// ユーザーの認証状態に応じて画面を切り替える
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return const SignInScreen();
            }
            return const MapScreen();
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }
}

// サインイン画面
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ログインしました')));
    } catch (e) {
      print(e);
      // エラーメッセージを表示
    }
  }

  Future<void> _signUp() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email, password: _password);
      User user = userCredential.user!;
      // ユーザー情報をFirestoreに保存
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': _email,
        'uid': user.uid,
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('登録が完了しました')));
    } catch (e) {
      print(e);
      // エラーメッセージを表示
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print('サインインキャンセル');
        return null; // サインインがキャンセルされた場合
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        User user = userCredential.user!;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'uid': user.uid,
        });
        print('Googleサインイン成功: ${userCredential.user!.uid}');
      } else {
        print('Googleサインイン失敗');
      }
      return userCredential.user;
    } catch (e) {
      print('Googleサインインエラー: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Geoshare ログイン'),
        ),
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                    ),
                    onChanged: (value) {
                      _email = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'パスワード',
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      _password = value;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await _signIn();
                        }
                      },
                      child: const Text('サインイン'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _signUp();
                      }
                    },
                    child: const Text('新規登録'),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        User? user = await _signInWithGoogle();
                        if (user != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Googleでログインしました')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
//                      backgroundColor: Colors.blue, // ボタンの背景色
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0), // 角を丸くしない
                        ),
                      ),
                      child: const Text('Googleでサインイン'),
                    ),
                  ),
//                const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ),
      );

      // Androidのときの処理
    } else if (Platform.isIOS) {
      return CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Geoshare ログイン'),
        ),
        backgroundColor: CupertinoColors.lightBackgroundGray,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoTextField(
                    placeholder: 'メールアドレス',
                    onChanged: (value) {
                      _email = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  CupertinoTextField(
                    placeholder: 'パスワード',
                    obscureText: true,
                    onChanged: (value) {
                      _password = value;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await _signIn();
                        }
                      },
                      child: const Text('サインイン'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _signUp();
                      }
                    },
                    child: const Text('新規登録'),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () async {
                        User? user = await _signInWithGoogle();
                        if (user != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Googleでログインしました')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(0),
                      child: const Text('Googleでサインイン'),
                    ),
                  ),
                  //                const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ),
      );

      // iOSのときの処理
    } else {
      return Container();
    }
  }
}

class QRCodeGenerator extends StatelessWidget {
  const QRCodeGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final User user = FirebaseAuth.instance.currentUser!;
    final String email = user.email!;

    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('自分のQRコード'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              QrImageView(
                data: email,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 50),
              Text(email),
            ],
          ),
        ),
      );
      // Androidのときの処理
    } else if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('自分のQRコード'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              QrImageView(
                data: email,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 50),
              Text(email),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}

class QRCodeScanner extends StatefulWidget {
  const QRCodeScanner({super.key});

  @override
  _QRCodeScannerState createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends State<QRCodeScanner> {
  String? result;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _scanQRCode() async {
    try {
      String scanResult = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'キャンセル', true, ScanMode.QR);
      if (scanResult != '-1') {
        setState(() {
          result = scanResult;
        });
        await _addSharingPartner(scanResult);
      }
    } catch (e) {
      print('QRコードのスキャンに失敗しました: $e');
    }
  }

  Future<void> _addSharingPartner(String partnerEmail) async {
    var result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: partnerEmail)
        .get();
    if (result.docs.isNotEmpty) {
      String partnerId = result.docs.first.id;
      User user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('partners')
          .doc(partnerId)
          .set({'addedAt': FieldValue.serverTimestamp()});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('共有相手を追加しました')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ユーザーが見つかりません')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QRコードスキャン'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _scanQRCode,
                child: const Text('QRコードをスキャン'),
              ),
              const SizedBox(height: 20),
              Text(result != null ? 'スキャン結果: $result' : 'QRコードをスキャンしてください'),
            ],
          ),
        ),
      );

      // Androidのときの処理
    } else if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('QRコードスキャン'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CupertinoButton(
                onPressed: _scanQRCode,
                color: CupertinoColors.activeBlue,
                child: const Text('QRコードをスキャン'),
              ),
              const SizedBox(height: 20),
              Text(result != null ? 'スキャン結果: $result' : 'QRコードをスキャンしてください'),
            ],
          ),
        ),
      );

      // iOSのときの処理
    } else {
      return Container();
    }
  }
}

// マップ画面
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  final Map<String, Marker> _markers = {};
  Timer? _locationUpdateTimer;

  @override
  void initState() {
//      print('=== inState ===');
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _checkLocationPermission() async {
//      print('=== _checkLocationPermission ===');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // パーミッションが得られなかった場合の処理
        return;
      }
    }
    _getCurrentLocation();
    _startLocationUpdates();
  }

  void _getCurrentLocation() async {
//      print('=== _getCurrentLocation ===');

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
//        _updateMyLocationMarker();
      });
    } catch (e) {
      print('位置情報の取得に失敗しました: $e');
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, distanceFilter: 5))
        .listen((Position position) {
      _currentPosition = position;
      setState(() {
//          _updateMyLocationMarker();
        _shareLocation(position); // 位置情報を共有
      });
    }, onError: (e) {
      print('位置情報の更新に失敗しました: $e');
    });

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPosition != null) {
//        _updateMyLocationMarker();
        _updatePartnerLocations();
//        _shareLocation(_currentPosition!);
      }
    });
  }

  void _shareLocation(Position position) async {
//      print('=== _shareLocation ===');
    User user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('locations').doc(user.uid).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _updateMyLocationMarker() {
    if (_currentPosition != null) {
      _markers['myLocation'] = Marker(
        markerId: const MarkerId('myLocation'),
        position:
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(title: '自分の位置'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }
  }

  // 共有相手の位置情報を更新
  void _updatePartnerLocations() async {
    User user = FirebaseAuth.instance.currentUser!;
    // 自分のマーカー以外をクリア
    setState(() {
      _markers.removeWhere((key, value) => key != 'myLocation');
    });
    // 共有相手の取得
    QuerySnapshot partnersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('partners')
        .get();
    for (var doc in partnersSnapshot.docs) {
      String partnerId = doc.id;
      // 共有相手の位置情報を取得
      DocumentSnapshot locationDoc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(partnerId)
          .get();
      if (locationDoc.exists) {
        double latitude = locationDoc['latitude'];
        double longitude = locationDoc['longitude'];
        // 共有相手のメールアドレスを取得
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(partnerId)
            .get();
        String partnerEmail = userDoc['email'] ?? 'Unknown';
        setState(() {
          _markers[partnerId] = Marker(
            markerId: MarkerId(partnerId),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: partnerEmail),
          );
        });
      }
    }
  }

  // 共有相手の追加
  void _addSharingPartner(String partnerEmail) async {
    var result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: partnerEmail)
        .get();
    if (result.docs.isNotEmpty) {
      String partnerId = result.docs.first.id;
      User user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('partners')
          .doc(partnerId)
          .set({'addedAt': FieldValue.serverTimestamp()});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('共有相手を追加しました')));
    } else {
      // エラーメッセージを表示
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ユーザーが見つかりません')));
    }
  }

  // 共有相手の削除
  void _removeSharingPartner(String partnerId) async {
    User user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('partners')
        .doc(partnerId)
        .delete();
    setState(() {
      _markers.remove(partnerId);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('共有相手を削除しました')));
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Geoshare'),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _updatePartnerLocations();
                }),
/*
          IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                _showAddPartnerDialog();
              }),
*/
            IconButton(
                icon: const Icon(Icons.group),
                onPressed: () {
                  _showManagePartnersDialog();
                }),
            IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const QRCodeGenerator()),
                  );
                }),
            IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const QRCodeScanner()),
                  );
                }),
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();
                  Navigator.of(context).pushReplacement(
//                    MaterialPageRoute(builder: (context) => SignInScreen()));
//                    MaterialPageRoute(builder: (context) => const AuthenticationWrapper()));
                      MaterialPageRoute(builder: (context) => const MyApp()));
                }),
          ],
        ),
        body: _currentPosition == null
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude),
                  zoom: 14.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _moveCameraToCurrentPosition();
                },
                markers: _markers.values.toSet(),
              ),
      );
    } else if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Geoshare',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.refresh),
                onPressed: () {
                  _updatePartnerLocations();
                },
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.group),
                onPressed: () {
                  _showManagePartnersDialog();
                },
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.qrcode),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const QRCodeGenerator()),
                  );
                },
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.qrcode_viewfinder),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const QRCodeScanner()),
                  );
                },
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.square_arrow_right),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();
                  Navigator.of(context).pushReplacement(
//                    CupertinoPageRoute(builder: (context) => const AuthenticationWrapper()),
                    CupertinoPageRoute(builder: (context) => const MyApp()),
                  );
                },
              ),
            ],
          ),
        ),
        child: _currentPosition == null
            ? const Center(child: CupertinoActivityIndicator())
            : GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude),
                  zoom: 14.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _moveCameraToCurrentPosition();
                },
                markers: _markers.values.toSet(),
              ),
      );
    } else {
      return Container();
    }
  }

  void _moveCameraToCurrentPosition() {
//      print('=== _moveCameraToCurrentPosition ===');

    if (_currentPosition != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ));
    }
  }

  void _showManagePartnersDialog() {
    if (Platform.isAndroid) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('共有相手の管理'),
              content: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('partners')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<DocumentSnapshot> partners = snapshot.data!.docs;
                    if (partners.isEmpty) {
                      return const Text('共有相手がいません');
                    }
                    return SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: partners.length,
                        itemBuilder: (context, index) {
                          String partnerId = partners[index].id;
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(partnerId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.hasData) {
                                String partnerEmail =
                                    userSnapshot.data!['email'] ?? 'Unknown';
                                return ListTile(
                                  title: Text(partnerEmail),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _removeSharingPartner(partnerId);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                );
                              } else {
                                return const ListTile(title: Text('読み込み中...'));
                              }
                            },
                          );
                        },
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('閉じる')),
              ],
            );
          });
      // Androidのときの処理
    } else if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              leading: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共有相手の管理',
                    style: TextStyle(
//                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.clear),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            child: SafeArea(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('partners')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<DocumentSnapshot> partners = snapshot.data!.docs;
                    if (partners.isEmpty) {
                      return const Center(child: Text('共有相手がいません'));
                    }
                    return CupertinoListSection(
                      children: partners.map((partner) {
                        String partnerId = partner.id;
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(partnerId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.hasData) {
                              String partnerEmail =
                                  userSnapshot.data!['email'] ?? 'Unknown';
                              return CupertinoListTile(
                                title: Text(partnerEmail),
                                trailing: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: const Icon(CupertinoIcons.delete),
                                  onPressed: () {
                                    _removeSharingPartner(partnerId);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            } else {
                              return const CupertinoListTile(
                                title: Text('読み込み中...'),
                              );
                            }
                          },
                        );
                      }).toList(),
                    );
                  } else {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                },
              ),
            ),
          );
        },
      );
      // iOSのときの処理
    }
  }
}
