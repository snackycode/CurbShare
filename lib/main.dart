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
      'Stripe Publish Key'; // your publishable key
  await Stripe.instance.applySettings();

  functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
    app: Firebase.app(),
  );

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
