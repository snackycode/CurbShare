import 'package:curbshare/provider/userDoc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HowitworkScreen extends StatelessWidget {
  const HowitworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDoc>(builder: (context, userProvider, child) {
      final user = userProvider.user;
      final role = user?.role ?? 'driver';
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF004991),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "How it works",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Color(0xFF004991),
            ),
          ),
        ),
        body: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  // Section 1: Download
                  Column(
                    children: [
                      Image.asset(
                        'icons/handscreen.png', // replace with your image
                        height: 180,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Download",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        "CurbShare app on your mobile",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Visit
                  Column(
                    children: [
                      Image.asset(
                        'icons/visit.png', // replace with your image
                        height: 180,
                      ),
                      const Text(
                        "Visit",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        role == 'driver'
                            ? "Join us to ease yourself with parking problems.\nCheckout a variety of parking spots."
                            : "Join us to earn yourself a side hustle.\nEasy way to make money with extra space.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Park
                  Column(
                    children: [
                      Image.asset(
                        'icons/carpink.png', // replace with your image
                        height: 180,
                      ),
                      const Text(
                        "Park",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        role == 'driver'
                            ? "Change your parking spot or parking lot \nwith one click"
                            : "Charge money by hourly or monthly based on host desired.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
