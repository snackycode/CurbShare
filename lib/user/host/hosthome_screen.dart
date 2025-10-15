import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:curbshare/user/host/addbooking_screen.dart';
import 'package:curbshare/user/host/editbooking_screen.dart';
import 'package:curbshare/user/host/hostlotdetail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HostHomeScreen extends StatefulWidget {
  const HostHomeScreen({super.key});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  String? get hostId => FirebaseAuth.instance.currentUser?.uid;

  Future<String?> fetchImageBase64(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('images')
          .doc(docId)
          .get();

      if (doc.exists && doc.data()?['image'] != null) {
        return doc.data()?['image'] as String;
      } else {
        print("No image found for $docId");
        return null;
      }
    } catch (e) {
      print("Error fetching image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        "CurbShare",
        style: TextStyle(
          fontFamily: 'Oswald',
          fontWeight: FontWeight.w600,
          fontSize: 26,
          color: Color(0xFF004991),
        ),
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HostAddBookScreen()));
            }),
      ],
    );
  }

  Widget _buildBody() {
    if (hostId == null) {
      return const Center(
        child: Text("You must be logged in to view your lots."),
      );
    }

    return Container(
      color: Colors.white, // White background
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("ParkingLot")
            .where("hostId", isEqualTo: hostId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black, // default text color
                  ),
                  children: [
                    const TextSpan(text: "No Parking Lots Yet. "),
                    TextSpan(
                      text: "Add Now",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF004991), // highlight color
                        decoration: TextDecoration.underline, // underline
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HostAddBookScreen(),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            );
          }

          final lots = snapshot.data!.docs
              .map((doc) => ParklotModel.fromDoc(doc))
              .toList();

          return ListView.builder(
            itemCount: lots.length,
            itemBuilder: (context, index) {
              return _buildLotCard(context, lots[index]);
            },
          );
        },
      ),
    );
  }

  /// UI card for each parklot (based on your screenshot)
  Widget _buildLotCard(BuildContext context, ParklotModel lot) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HostLotDetailScreen(lot: lot), // pass the lot
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildFirebaseImageFromBase64(
            //     lot.img),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                color: Color.fromRGBO(0, 73, 145, 1),
                size: 36,
              ),
            ),
            const SizedBox(width: 12),

            // Main Info (Name + Available time)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lot Name
                  SizedBox(
                    height: 45,
                    width: 150,
                    child: Text(
                      lot.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.4, // controls line spacing
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Available From - Close Before
                  Text(
                    "${DateFormat("dd MMM, h:mm a").format(lot.availableFrom ?? DateTime.now())} - ${lot.closeBefore != null ? DateFormat("dd MMM, h:mm a").format(lot.closeBefore!) : "--"}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Right side (CreatedAt + Parking/EV + Edit)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Created At
                const SizedBox(height: 2),

                Text(
                  lot.createdAt != null
                      ? DateFormat("dd MMM, h:mm a").format(lot.createdAt!)
                      : "--",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),

                // Parking & EV Info
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_parking,
                        size: 16, color: Color(0xFF004991)),
                    const SizedBox(width: 4),
                    Text(
                      "${lot.capacity - lot.occupied}/${lot.capacity}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF004991),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.ev_station,
                        size: 16, color: Color(0xFF004991)),
                    const SizedBox(width: 4),
                    Text(
                      lot.echarge ? "Yes" : "No",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF004991),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Edit Button (moved here)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditBookingScreen(lot: lot),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromRGBO(0, 73, 145, 1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Color.fromRGBO(0, 73, 145, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseImageFromBase64(String? base64String) {
    return Container(
      width: 80,
      height: 80,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: base64String == null
          ? const Icon(Icons.image, size: 40, color: Colors.white)
          : Image.memory(
              base64Decode(base64String),
              fit: BoxFit.cover,
              width: 80,
              height: 80,
            ),
    );
  }
}
