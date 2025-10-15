import 'package:curbshare/login/login_screen.dart';
import 'package:curbshare/main_screen.dart';
import 'package:curbshare/provider/userDoc.dart';
import 'package:curbshare/user/driver/booking_screen.dart';
import 'package:curbshare/user/driver/googlemap_screen.dart';
import 'package:curbshare/user/driver/home_screen.dart';
import 'package:curbshare/user/driver/noti_screen.dart';
import 'package:curbshare/user/driver/profile_screen.dart';
import 'package:curbshare/user/host/hostHome_screen.dart';
import 'package:curbshare/user/host/hostbook_screen.dart';
import 'package:curbshare/user/host/hostnoti_screen.dart';
import 'package:curbshare/user/host/hostprofile_screen.dart';
// make sure correct import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// class Wrapper extends StatelessWidget {
//   const Wrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) return const LoginScreen();

//         final user = snapshot.data!;

//         return FutureBuilder<DocumentSnapshot>(
//           future: FirebaseFirestore.instance
//               .collection('User') // make sure it matches your provider
//               .doc(user.uid)
//               .get(),
//           builder: (context, userDocSnapshot) {
//             if (userDocSnapshot.connectionState == ConnectionState.waiting) {
//               return const Scaffold(
//                   body: Center(child: CircularProgressIndicator()));
//             }

//             // Firestore document exists → ProfileScreen
//             if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
//               return const ProfileScreen();
//             }

//             // Firestore document does NOT exist → SignupScreen
//             return SignupScreen(
//               initialEmail: user.email,
//               initialPhone: user.phoneNumber,
//             );
//           },
//         );
//       },
//     );
//   }
// }

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {

  
  @override
  Widget build(BuildContext context) {
    return Consumer<UserDoc>(builder: (context, userProvider, child) {
      // Not logged in
      if (!FirebaseAuth.instance.isSignInWithEmailLink('') &&
          !userProvider.isLoggedIn) {
        return const LoginScreen();
      }

      // User data loading
      if (userProvider.user == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final role = userProvider.user!.role;

      if (role == 'driver') {
        return MainScreen(
          homeScreen: HomeScreen(),
          bookingScreen: BookingScreen(),
          notiScreen: NotiScreen(),
          profScreen: ProfileScreen(),
        );
      } else if (role == 'host') {
        return MainScreen(
          homeScreen: HostHomeScreen(),
          bookingScreen: HostBookScreen(),
          notiScreen: HostNotiScreen(),
          profScreen: HostProfileScreen(),
        );
      } else {
        return const Scaffold(
          body: Center(child: Text('Unknown role')),
        );
      }
    }
        // User exists → ProfileScreen
        // return const MainScreen();
        );
  }
}
