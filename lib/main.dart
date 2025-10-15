import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:curbshare/login/auth_gate.dart';
import 'package:curbshare/services/noti_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uni_links/uni_links.dart';
import 'firebase_options.dart';
import 'package:curbshare/provider/userDoc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curbshare/provider/BottomNavVisibilityProvider.dart';
import 'package:curbshare/provider/navigateProvider.dart';

late final FirebaseFunctions functions;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final notiService = NotiService();
  await notiService.saveFcmToken();
  notiService.listenToFcmMessages();

  Stripe.publishableKey =
      'input your publish'; // your publishable key
  await Stripe.instance.applySettings();

  // final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  // functions.useFunctionsEmulator('localhost', 5001);
  // FirebaseAuth.instance.useAuthEmulator('192.168.50.22', 9099);

  // FirebaseFunctions.instanceFor(region: 'us-central1')
  //     .useFunctionsEmulator('192.168.3.61', 5001);

  // For deployed functions, do NOT use emulator
  functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
    app: Firebase.app(),
  );

  // FirebaseFirestore.instance.useFirestoreEmulator('192.168.50.22', 8080);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final userDoc = UserDoc();
            userDoc.fetchUser(); //
            return userDoc;
          },
        ),
        ChangeNotifierProvider(create: (_) => BottomNavVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => TabIndexProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    // _initDeepLinks();
  }

  // void _initDeepLinks() {
  //   _linkSub = uriLinkStream.listen((Uri? uri) {
  //     if (uri == null) return;

  //     if (uri.path == '/stripe/return') {
  //       // ✅ Stripe onboarding finished successfully
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Stripe onboarding completed ✅')),
  //       );
  //       // TODO: maybe refresh user Firestore doc here
  //     } else if (uri.path == '/stripe/refresh') {
  //       // ❌ User canceled or session expired
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Please restart onboarding ❌')),
  //       );
  //     }
  //   }, onError: (err) {
  //     print('Deep link error: $err');
  //   });
  // }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      debugShowCheckedModeBanner: false,
      home: const Wrapper(),
      // home: ScanQrScreen(),
    );
  }
}

// Only For Creating Dummy Lot then Comment it out
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   await addDummyLotsForUser("AHImCpjuZ7bNRsSL20iTD9jyrNI2");
//   print("✅ Dummy lots created successfully for the user!");
// }

// Future<void> addDummyLotsForUser(String userId) async {
//   final firestore = FirebaseFirestore.instance;
//   final batch = firestore.batch();
//   final collection = firestore.collection('ParkingLot');
//   final random = Random();

//   // Base area locations (approximate Phnom Penh coordinates)
//   final baseLocations = {
//     'Psar Neak Meas': const GeoPoint(11.5662, 104.8925),
//     'Psar Dermkor': const GeoPoint(11.5659, 104.8837),
//     'Olympic': const GeoPoint(11.5575, 104.9170),
//     'Orussey': const GeoPoint(11.5698, 104.9177),
//     'Psar Tmey': const GeoPoint(11.5636, 104.9212),
//   };

//   for (final entry in baseLocations.entries) {
//     final areaName = entry.key;
//     final base = entry.value;

//     for (int i = 0; i < 2; i++) {
//       final lat = base.latitude + (random.nextDouble() - 0.5) / 500; // small offset
//       final lng = base.longitude + (random.nextDouble() - 0.5) / 500;

//       final capacity = 8 + random.nextInt(25);
//       final hourlyRate = double.parse((1 + random.nextDouble() * 2).toStringAsFixed(2));
//       final dailyRate = double.parse((5 + random.nextDouble() * 10).toStringAsFixed(2));
//       final monthlyRate = double.parse((50 + random.nextDouble() * 50).toStringAsFixed(2));
//       final availableFrom = DateTime.now().subtract(Duration(days: random.nextInt(3)));
//       final closeBefore = DateTime.now().add(Duration(days: 30 + random.nextInt(30)));
//       final echarge = random.nextBool();
//       final occupied = random.nextInt(capacity);
//       final createdAt = DateTime.now();

//       final docRef = collection.doc();

//       final dummyLot = {
//         'id': docRef.id,
//         'hostId': userId,
//         'img': 'https://via.placeholder.com/400x200.png?text=$areaName+Lot+${i + 1}',
//         'name': '$areaName Lot ${i + 1}',
//         'location': GeoPoint(lat, lng),
//         'desc': 'Convenient parking spot in $areaName area with secure access.',
//         'capacity': capacity,
//         'hourlyRate': hourlyRate,
//         'dailyRate': dailyRate,
//         'monthlyRate': monthlyRate,
//         'availableFrom': Timestamp.fromDate(availableFrom),
//         'closeBefore': Timestamp.fromDate(closeBefore),
//         'echarge': echarge,
//         'occupied': occupied,
//         'createdAt': Timestamp.fromDate(createdAt),
//       };

//       batch.set(docRef, dummyLot);
//     }
//   }

//   await batch.commit();
//   print('🚗 10 dummy parking lots added for user $userId');
// }