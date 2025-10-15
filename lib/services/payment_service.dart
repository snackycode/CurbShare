import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/main_screen.dart';
import 'package:curbshare/provider/navigateProvider.dart';
import 'package:curbshare/user/driver/booking_screen.dart';
import 'package:curbshare/user/driver/home_screen.dart';
import 'package:curbshare/user/driver/noti_screen.dart';
import 'package:curbshare/user/driver/profile_screen.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

class PaymentService {
  static Future<void> startBookingAndPay({
    required BuildContext context,
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
        "checkin": null,
        "checkout": null,
        "vehicleName": null,
        "notifiedDriver": false,
        "notifiedHost": false,
        'overstayFeePaid': false,
        'overstayFeeAmount': null,
      });
    });
    if (context.mounted) {
      // Navigate to MainScreen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            homeScreen: HomeScreen(),
            bookingScreen: BookingScreen(),
            notiScreen: NotiScreen(),
            profScreen: ProfileScreen(),
          ),
        ),
        (route) => false,
      );

      // Optionally, set the Booking tab after navigation
      final tabProvider = context.read<TabIndexProvider>();
      tabProvider.setIndex(1); // 1 = Booking tab
    }
  }

  static Future<void> payOverstayFee({
    required BuildContext context,
    required String bookingId,
    required double feeAmount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No logged-in user");

    final driverId = user.uid;
    final driverRef =
        FirebaseFirestore.instance.collection('User').doc(driverId);
    final bookingRef =
        FirebaseFirestore.instance.collection('Booking').doc(bookingId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final driverSnap = await tx.get(driverRef);
        final bookingSnap = await tx.get(bookingRef);

        final driverBalance = (driverSnap['balance'] ?? 0).toDouble();
        final overstayPaid = bookingSnap['overstayFeePaid'] ?? false;

        if (overstayPaid) {
          throw Exception("Overstay fee already paid");
        }

        if (driverBalance < feeAmount) {
          throw Exception("Insufficient balance to pay overstay fee");
        }

        // Deduct balance
        tx.update(driverRef, {'balance': driverBalance - feeAmount});
        print('Booking ID: $bookingId, Overstay fee: $feeAmount');
        print(
            'Driver previous balance: $driverBalance, new balance: ${driverBalance - feeAmount}');
        // Mark fee as paid
        tx.update(bookingRef, {
          'overstayFeePaid': true,
          'overstayFeeAmount': feeAmount,
          'checkout': DateTime.now(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Overstay fee of \$$feeAmount paid successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: ${e.toString()}")),
      );
    }
  }
}
