// import 'package:curbshare/provider/BottomNavVisibilityProvider.dart';
// import 'package:curbshare/provider/navigateProvider.dart';
// import 'package:curbshare/provider/userDoc.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//           ChangeNotifierProvider(create: (context) => UserDoc()),
//           ChangeNotifierProvider(create: (context) => TabIndexProvider()),
//           ChangeNotifierProvider(create: (context)=> BottomNavVisibilityProvider()),
//       ],
//       child: FutureBuilder(
//         future: Firebase.initializeApp(), 
//         builder: (context, snapshot) {
//           if (snapshot.hasError){
//             print("Error: ${snapshot.error}");
//             return _buildMaterial(
//               const Scaffold(body: Center(child: Text("Error Firebase"),))
//             );
//           }

//           if(snapshot.connectionState == ConnectionState.done){
//             return _buildMaterial(const SplashScreen());
//           } else{
//             return _buildMaterial(const Center(
//               child: Scaffold(body: CircularProgressIndicator(),),
//             ));
//           }
//         }));
//   }

//   _buildMaterial(Widget home){
//     return MaterialApp(debugShowCheckedModeBanner: false, home: home);
//   }
// }
