import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:curbshare/provider/BottomNavVisibilityProvider.dart';
import 'package:curbshare/provider/navigateProvider.dart';
import 'package:curbshare/user/driver/booking_screen.dart';
import 'package:curbshare/user/driver/googlemap_screen.dart';
import 'package:curbshare/user/driver/noti_screen.dart';
import 'package:curbshare/user/driver/profile_screen.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  final Widget homeScreen;
  final Widget bookingScreen;
  final Widget notiScreen;
  final Widget profScreen;
  const MainScreen({super.key, required this.homeScreen, required this.bookingScreen, required this.notiScreen, required this.profScreen});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    int currentIndex = context.watch<TabIndexProvider>().currentIndex;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children:  [
          widget.homeScreen,
          widget.bookingScreen,
          widget.notiScreen,
          widget.profScreen,
          // MapSearchScreen(),
          // // HomeScreen(), // 0
          // BookingScreen(), // 1
          // NotiScreen(), // 2
          // ProfileScreen() // 3
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    int currentIndex = context.watch<TabIndexProvider>().currentIndex;
    bool isVisible = context.watch<BottomNavVisibilityProvider>().isVisible;

    if (!isVisible) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        child: BlurryContainer(
          padding: EdgeInsets.zero,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(10),
            bottom: Radius.circular(18),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(59, 120, 195, 1),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(10),
                bottom: Radius.circular(18),
              ),
            ),
            child: BottomNavigationBar(
              elevation: 40,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 24,
              unselectedItemColor: Colors.white,
              selectedItemColor: const Color.fromARGB(255, 0, 47, 95),
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: (index) {
              //   if (index != 2) {
              //     // normal tab navigation
                  context.read<TabIndexProvider>().currentIndex = index;
                },
                //  else {
              //     // special action for tab index 2 (Post)
              //     User? user = FirebaseAuth.instance.currentUser;
              //     if (user != null) {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => const PostScreen(postType: 'Post'),
              //         ),
              //       );
              //     } else {
              //       showGuestSnackBar(context);
              //     }
              //   }
              // },
              items: const [
                BottomNavigationBarItem(
                  label: "Home",
                  icon: ImageIcon(
                    AssetImage('icons/searchicon.png'),
                    size: 25,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Booking",
                  icon: ImageIcon(
                    AssetImage('icons/bookicon.png'),
                    size: 25,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Post", // 🔑 still needs label, even if hidden
                  icon: ImageIcon(
                    AssetImage('icons/notiicon.png'),
                    size: 25,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Profile",
                  icon: ImageIcon(
                    AssetImage('icons/accicon.png'),
                    size: 27,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
