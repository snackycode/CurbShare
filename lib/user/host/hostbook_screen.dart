import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/booking_model.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:curbshare/user/host/hosthome_screen.dart';
import 'package:curbshare/user/host/hostlotdetail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HostBookScreen extends StatefulWidget {
  const HostBookScreen({super.key});

  @override
  State<HostBookScreen> createState() => _HostBookScreenState();
}

class _HostBookScreenState extends State<HostBookScreen> {
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
      title: Text(
        "Booking",
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: Color(0xFF004991),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text("You must be logged in to view your bookings."),
      );
    }

    return Container(
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Booking")
              .where("hostId", isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: "You have no bookings yet. ",
                      ),
                      TextSpan(
                        text: "Book Now",
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
                                builder: (context) => const HostHomeScreen(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              );
            }
            final books = snapshot.data!.docs
                .map((doc) => BookingModel.fromDoc(doc))
                .toList();

            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                return _buildBookCard(context, books[index]);
              },
            );
          }),
    );
  }

  Widget _buildBookCard(BuildContext context, BookingModel book) {
    
    final duration = book.end.difference(book.start); // Duration object
    String durationText;

    if (book.reservationType == "monthly") {
      durationText = "${duration.inDays}d"; // show in days
    } else if (book.reservationType == "daily") {
      durationText = "${duration.inHours}h"; // daily → hours
    } else {
      durationText = "${duration.inHours}h"; // hourly → hours
    }

    return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("ParkingLot")
            .doc(book.lotId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox(); // Or show "Lot not found"
          }

          final lot = ParklotModel.fromDoc(snapshot.data!);
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HostLotDetailScreen(lot: lot,booking: book,),
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

                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Vehicle PlateNumber: ",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color.fromARGB(124, 0, 73, 145),
                                ),
                              ),
                              TextSpan(
                                text: book.vehicleName ?? "None",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF004991),
                                  fontWeight: FontWeight.bold, // optional
                                ),
                              ),
                            ],
                          ),
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
                        "Duration: $durationText",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF004991),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Charge: \$${book.budget.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF004991),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        book.checkin == null
                            ? "pending"
                            : (book.checkout == null ? "ongoing" : "completed"),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: book.checkin == null
                              ? Colors.orange
                              : (book.checkout == null
                                  ? Colors.red
                                  : Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }
}
