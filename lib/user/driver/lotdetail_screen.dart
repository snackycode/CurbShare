import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:curbshare/services/location_service.dart';
import 'package:curbshare/services/payment_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

class LotDetailScreen extends StatefulWidget {
  final ParklotModel lot;
  final DateTime startDate;
  final DateTime endDate;
  final String bookingType;
  final GeoPoint selectedPosition;
  const LotDetailScreen(
      {super.key,
      required this.lot,
      required this.startDate,
      required this.endDate,
      required this.bookingType,
      required this.selectedPosition});

  @override
  State<LotDetailScreen> createState() => _LotDetailScreenState();
}

class _LotDetailScreenState extends State<LotDetailScreen> {
  final _locationService = LocationService();
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> _openGoogleMap() async {
    final lat = widget.lot.location.latitude;
    final lng = widget.lot.location.longitude;
    final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Future<void> createBookingPayment({
  //   required String lotId,
  //   required String hostId,
  //   required DateTime start,
  //   required DateTime end,
  //   required String bookingType,
  //   required double amount,
  // }) async {
  //   final dio = Dio();
  //   final user = FirebaseAuth.instance.currentUser;

  //   if (user == null) throw Exception("No user logged in");

  //   final response = await dio.post(
  //     "https://us-central1-curbshare-22cs17.cloudfunctions.net/createPaymentIntent",
  //     data: {
  //       "lotId": lotId,
  //       "hostId": hostId,
  //       "start": start.toIso8601String(),
  //       "end": end.toIso8601String(),
  //       "bookingType": bookingType,
  //       "currency": "usd",
  //       "amount": (amount * 100).toInt(), // cents
  //     },
  //     options: Options(
  //       headers: {"Content-Type": "application/json"},
  //       validateStatus: (_) =>
  //           true, // optional: allows reading response even on error
  //     ),
  //   );

  //   final clientSecret = response.data['clientSecret'];
  //   final bookingId = response.data['bookingId'];

  //   // 1️⃣ Confirm Stripe PaymentIntent
  //   await Stripe.instance.initPaymentSheet(
  //     paymentSheetParameters: SetupPaymentSheetParameters(
  //       paymentIntentClientSecret: clientSecret,
  //       merchantDisplayName: "CurbShare Parking",
  //     ),
  //   );
  //   await Stripe.instance.presentPaymentSheet();

  //   // 2️⃣ Update Firestore balances (driver - amount, host + amount)
  //   final driverRef =
  //       FirebaseFirestore.instance.collection('User').doc(user.uid);
  //   final hostRef = FirebaseFirestore.instance.collection('User').doc(hostId);
  //   final bookingRef =
  //       FirebaseFirestore.instance.collection('Booking').doc(bookingId);

  //   await FirebaseFirestore.instance.runTransaction((tx) async {
  //     final driverSnap = await tx.get(driverRef);
  //     final hostSnap = await tx.get(hostRef);

  //     final driverBalance = (driverSnap['balance'] ?? 0).toDouble();
  //     final hostBalance = (hostSnap['balance'] ?? 0).toDouble();

  //     if (driverBalance < amount) throw Exception("Insufficient balance");

  //     tx.update(driverRef, {'balance': driverBalance - amount});
  //     tx.update(hostRef, {'balance': hostBalance + amount});

  //     tx.set(bookingRef, {
  //       "lotId": lotId,
  //       "driverId": user.uid,
  //       "hostId": hostId,
  //       "start": start,
  //       "end": end,
  //       "budget": amount,
  //       "reservationType": bookingType,
  //       "paymentIntentId": clientSecret,
  //       "paymentStatus": "succeeded",
  //     });
  //   });
  // }

  // Future<void> startBookingAndPay({
  //   required String lotId,
  //   required String hostId,
  //   required DateTime start,
  //   required DateTime end,
  //   required String bookingType,
  //   required int amount, // in cents
  //   required BuildContext context,
  // }) async {
  //   final dio = Dio();
  //   final url =
  //       'https://us-central1-curbshare-22cs17.cloudfunctions.net/createPaymentIntent';

  //   try {
  //     final response = await dio.post(
  //       url,
  //       data: {
  //         'lotId': lotId,
  //         'hostId': hostId,
  //         'start': start.toIso8601String(),
  //         'end': end.toIso8601String(),
  //         'bookingType': bookingType,
  //         'currency': 'usd',
  //         "amount": (amount * 100).toInt(),
  //       },
  //       options: Options(
  //         headers: {'Content-Type': 'application/json'},
  //       ),
  //     );

  //     final clientSecret = response.data['clientSecret'];

  //     // Initialize Stripe PaymentSheet
  //     await Stripe.instance.initPaymentSheet(
  //       paymentSheetParameters: SetupPaymentSheetParameters(
  //         paymentIntentClientSecret: clientSecret,
  //         merchantDisplayName: 'CurbShare Parking',
  //       ),
  //     );

  //     await Stripe.instance.presentPaymentSheet();

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //           content: Text('Payment successful — booking pending confirmation')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Payment failed: $e')),
  //     );
  //   }
  // }

  Future<void> startBookingAndPay({
    required String lotId,
    required String hostId, // use this directly
    required DateTime start,
    required DateTime end,
    required String bookingType,
    required double amount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No logged-in user");

    final driverId = user.uid;

    // Call backend Cloud Function for demo Stripe bank payment
    final dio = Dio();
    final response = await dio.post(
      "https://us-central1-curbshare-22cs17.cloudfunctions.net/createPaymentIntent",
      data: {
        "lotId": lotId,
        "driverId": driverId,
        "hostId": hostId,
        "amount": (amount * 100).toInt(), // cents
        "currency": "usd",
        "bookingType": bookingType,
      },
      options: Options(headers: {"Content-Type": "application/json"}),
    );

    final clientSecret = response.data['clientSecret'];
    final paymentIntentId = response.data['paymentIntentId'];

    // Since this is us_bank_account / demo, we can mock confirmation
    // Optionally, you can still use Stripe PaymentSheet if desired
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: "CurbShare Parking",
      ),
    );
    await Stripe.instance.presentPaymentSheet();

    // Update Firebase balances for demo
    final driverRef =
        FirebaseFirestore.instance.collection('User').doc(driverId);
    final hostRef = FirebaseFirestore.instance.collection('User').doc(hostId);
    final lotRef =
        FirebaseFirestore.instance.collection('ParkingLot').doc(lotId);
    final bookingRef = FirebaseFirestore.instance.collection('Booking').doc();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final driverSnap = await tx.get(driverRef);
      final hostSnap = await tx.get(hostRef);
      final lotSnap = await tx.get(lotRef);
      final driverBalance = (driverSnap['balance'] ?? 0).toDouble();
      final hostBalance = (hostSnap['balance'] ?? 0).toDouble();
      final occupied = (lotSnap['occupied'] ?? 0).toInt();
      final capacity = (lotSnap['capacity'] ?? 0).toInt();

      if (driverBalance < amount) throw Exception("Insufficient balance");
      if (occupied >= capacity) throw Exception("Parking lot full");
      final platformFee = amount * 0.1;
      final hostReceives = amount - platformFee;

      tx.update(driverRef, {'balance': driverBalance - amount});
      tx.update(hostRef, {'balance': hostBalance + hostReceives});
      tx.update(lotRef, {'occupied': occupied + 1});
      tx.set(bookingRef, {
        "lotId": lotId,
        "driverId": driverId,
        "hostId": hostId,
        "budget": amount,
        "platformFee": platformFee,
        "hostReceives": hostReceives,
        "paymentIntentId": paymentIntentId,
        "paymentStatus": "succeeded",
        "reservationType": bookingType,
        "start": start,
        "end": end,
        "createdAt": FieldValue.serverTimestamp(),
      });
    });

    print("✅ Demo booking completed: Driver -$amount, Host +${amount * 0.9}");
  }

  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;
    double distance = _locationService.calculateDistanceKm(
      widget.selectedPosition.latitude,
      widget.selectedPosition.longitude,
      lot.location.latitude,
      lot.location.longitude,
    );

    // Duration
    final duration = widget.endDate.difference(widget.startDate);

    // Price
    String priceText;
    switch (widget.bookingType.toLowerCase()) {
      case 'hourly':
        priceText = "\$${lot.hourlyRate.toStringAsFixed(2)} / h";
        break;
      case 'daily':
        priceText = "\$${lot.dailyRate.toStringAsFixed(2)} / d";
        break;
      case 'monthly':
        priceText = "\$${lot.monthlyRate.toStringAsFixed(2)} / m";
        break;
      default:
        priceText = "\$${lot.hourlyRate.toStringAsFixed(2)} / h";
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          // Collapsing image header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 119, 187, 255),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF004991),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildFirebaseImageFromBase64(lot.img),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004991),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk,
                          size: 16, color: Color(0xFF004991)),
                      const SizedBox(width: 4),
                      Text("${distance.toStringAsFixed(1)} km"),
                      const SizedBox(width: 12),
                      const Icon(Icons.local_parking,
                          size: 16, color: Color(0xFF004991)),
                      const SizedBox(width: 4),
                      Text("${lot.capacity - lot.occupied}/${lot.capacity}"),
                      const SizedBox(width: 12),
                      const Icon(Icons.ev_station,
                          size: 16, color: Color(0xFF004991)),
                      const SizedBox(width: 4),
                      Text(lot.echarge ? "Yes" : "No"),
                    ],
                  ),

                  const Divider(height: 25),
                  // Availability
                  Text(
                    "Available: ${dateFormat.format(widget.startDate)} - ${dateFormat.format(widget.endDate)}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(59, 120, 195, 0.642),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.radio_button_off,
                                size: 18, color: Color(0xFF004991)),
                            const SizedBox(width: 8),
                            const Text("Check-in",
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF004991))),
                            const Spacer(),
                            Text(
                              dateFormat.format(widget.startDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.radio_button_on,
                                size: 18, color: Color(0xFF004991)),
                            const SizedBox(width: 8),
                            const Text("Check-out",
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF004991))),
                            const Spacer(),
                            Text(
                              dateFormat.format(widget.endDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Parking Type: ",
                          style: TextStyle(
                            color: Color.fromRGBO(59, 120, 195, 0.642),
                          )),
                      Text(
                        widget.bookingType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(59, 120, 195, 0.642),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.bookingType == "monthly"
                            ? "${duration.inDays}d"
                            : "${duration.inHours}h",
                        style: const TextStyle(color: Color(0xFF004991)),
                      ),
                    ],
                  ),

                  const Divider(height: 25),
                  const Text(
                    "Parking Location:",
                    style: TextStyle(
                      color: Color.fromRGBO(59, 120, 195, 0.642),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Map preview
                  GestureDetector(
                    onTap: _openGoogleMap,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              lot.location.latitude, lot.location.longitude),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(lot.id),
                            position: LatLng(
                                lot.location.latitude, lot.location.longitude),
                          )
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        scrollGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  ReadMoreText(
                    lot.desc,
                    trimLines: 5, // show 5 lines initially
                    colorClickableText: const Color(0xFF004991),
                    trimMode: TrimMode.Line,
                    trimCollapsedText: '...Read more',
                    trimExpandedText: ' Read less',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    moreStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004991),
                    ),
                    lessStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004991),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      // ✅ FIX: bottomNavigationBar moved here
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              priceText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 7, 108, 209),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final amount = _locationService.calculatePrice(
                    lot: lot,
                    bookingType: widget.bookingType,
                    start: widget.startDate,
                    end: widget.endDate,
                  );

                  // Use lot.hostId from the selected ParkingLot
                  // await startBookingAndPay(
                  // lotId: lot.id,
                  // hostId: lot.hostId,
                  // start: widget.startDate,
                  // end: widget.endDate,
                  // bookingType: widget.bookingType,
                  // amount: amount,
                  // );

                  await PaymentService.startBookingAndPay(
                    context: context,
                    lotId: lot.id,
                    hostId: lot.hostId,
                    start: widget.startDate,
                    end: widget.endDate,
                    bookingType: widget.bookingType,
                    amount: amount,
                  );
                  setState(() {
                    lot.occupied = (lot.occupied ?? 0) + 1;
                  });
                  // Optionally show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Booking successful!")),
                  );
                } catch (e) {
                  // Handle errors
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(
                    255, 7, 108, 209), // outlined style with white bg
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text(
                "Book",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // match border
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseImageFromBase64(String? base64String) {
    if (base64String == null) {
      // fallback
      return Icon(Icons.image, size: 40, color: Colors.white);
    }

    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
