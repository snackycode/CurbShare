import 'package:curbshare/login/login_screen.dart';
import 'package:curbshare/main_screen.dart';
import 'package:curbshare/provider/navigateProvider.dart';
import 'package:curbshare/provider/userDoc.dart';
import 'package:curbshare/user/driver/contactus_screen.dart';
import 'package:curbshare/user/driver/edit_screen.dart';
import 'package:curbshare/user/driver/howitwork_screen.dart';
import 'package:curbshare/user/host/hostbook_screen.dart';
import 'package:curbshare/user/host/hosthome_screen.dart';
import 'package:curbshare/user/host/hostnoti_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HostProfileScreen extends StatefulWidget {
  const HostProfileScreen({super.key});

  @override
  State<HostProfileScreen> createState() => _HostProfileScreenState();
}

class _HostProfileScreenState extends State<HostProfileScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  Future<void> signOutUniversal(BuildContext context) async {
    final userProvider = Provider.of<UserDoc>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // Only disconnect Google if the user signed in with Google
      final isGoogle =
          user.providerData.any((p) => p.providerId == 'google.com');

      if (isGoogle) {
        // Safe Google sign-out
        final GoogleSignIn googleSignIn = GoogleSignIn();
        try {
          await googleSignIn.disconnect();
        } catch (_) {} // ignore if already disconnected
        try {
          await googleSignIn.signOut();
        } catch (_) {} // ignore errors
      }

      // Firebase sign-out (works for phone, email, or Google)
      await FirebaseAuth.instance.signOut();

      // Reset provider state
      userProvider.resetUser();

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signed out successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error signing out: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDoc>(
      builder: (context, userProvider, child) {
        if (userProvider.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userProvider.user!;

        return Scaffold(
          appBar: _buildAppBar(userProvider),
          body: _buildBody(),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80.0, right: 10.0),
            child: FloatingActionButton(
              onPressed: () {
                // Handle sign out logic here
                signOutUniversal(context); // Example
              },
              backgroundColor: Color.fromRGBO(59, 120, 195, 1),
              child: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.endFloat, // Bottom-right
        );
      },
    );
  }

  AppBar _buildAppBar(UserDoc userProvider) {
    // Prefer provider user info first, fallback to FirebaseAuth
    final userModel = userProvider.user;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final displayName = userModel?.name ?? firebaseUser?.displayName ?? 'N/A';
    final phone = userModel?.phone ?? firebaseUser?.phoneNumber ?? 'N/A';

    return AppBar(
      backgroundColor: Colors.white,
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profile",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: Color(0xFF004991),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$displayName",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF004991),
                  ),
                ),
                Text(
                  phone != null && phone.isNotEmpty ? phone : 'N/A',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color.fromARGB(134, 0, 73, 145),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final userProvider = Provider.of<UserDoc>(context, listen: false);
    final user = userProvider.user;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: icon + text
              Row(
                children: [
                  ImageIcon(
                    AssetImage('icons/accicon.png'),
                    color: Color.fromRGBO(0, 73, 145, 1),
                    size: 35,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "My personal details",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(0, 73, 145, 1),
                    ),
                  ),
                ],
              ),

              // Right side: Edit
              GestureDetector(
                onTap: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditScreen(user: user),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Edit",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color.fromARGB(134, 0, 73, 145),
                  ),
                ),
              )
            ]),
        Divider(height: 20),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: icon + text
              Row(
                children: [
                  ImageIcon(
                    AssetImage('icons/vehicle.png'),
                    color: Color.fromRGBO(0, 73, 145, 1),
                    size: 35,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "My Parkings",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(0, 73, 145, 1),
                    ),
                  ),
                ],
              ),

              // Right side: Edit
              GestureDetector(
                onTap: () {
                  if (user != null) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MainScreen(
                          homeScreen: HostHomeScreen(),
                          bookingScreen: HostBookScreen(),
                          notiScreen: HostNotiScreen(),
                          profScreen: HostProfileScreen(),
                        ),
                      ),
                      (route) => false,
                    );

                    // Optionally, set the Booking tab after navigation
                    final tabProvider = context.read<TabIndexProvider>();
                    tabProvider.setIndex(0); // 1 = Booking tab
                  }
                },
                child: const Text(
                  "Add",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color.fromARGB(134, 0, 73, 145),
                  ),
                ),
              )
            ]),
        Divider(height: 20),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: icon + text
              Row(
                children: [
                  ImageIcon(
                    AssetImage('icons/contact.png'),
                    color: Color.fromRGBO(0, 73, 145, 1),
                    size: 35,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Customer service",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(0, 73, 145, 1),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  // Message you want to send
                  final message = "Hello CurbShare";

                  // Telegram username to send message to
                  final username = "LimAnkim";

                  // Telegram URL scheme
                  final url = Uri.parse(
                    "https://t.me/$username?text=${Uri.encodeComponent(message)}",
                  );

                  // Launch Telegram
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Could not open Telegram."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Icon(
                  Icons.navigate_next,
                  color: Color.fromRGBO(0, 73, 145, 1),
                ),
              )
            ]),
        Divider(height: 20),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: icon + text
              Row(
                children: [
                  ImageIcon(
                    AssetImage('icons/how.png'),
                    color: Color.fromRGBO(0, 73, 145, 1),
                    size: 35,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "How it works",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(0, 73, 145, 1),
                    ),
                  ),
                ],
              ),

              GestureDetector(
                onTap: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HowitworkScreen(),
                      ),
                    );
                  }
                },
                child: const Icon(
                  Icons.navigate_next,
                  color: Color.fromRGBO(0, 73, 145, 1),
                ),
              )
            ]),
        Divider(height: 20),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: icon + text
              Row(
                children: [
                  ImageIcon(
                    AssetImage('icons/about.png'),
                    color: Color.fromRGBO(0, 73, 145, 1),
                    size: 35,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Contact us",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(0, 73, 145, 1),
                    ),
                  ),
                ],
              ),

              GestureDetector(
                onTap: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContactusScreen(),
                      ),
                    );
                  }
                },
                child: const Icon(
                  Icons.navigate_next,
                  color: Color.fromRGBO(0, 73, 145, 1),
                ),
              )
            ]),
        Divider(height: 20),
      ]),
    );
  }
}
