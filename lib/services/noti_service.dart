import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:curbshare/model/booking_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotiService {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final String userId = FirebaseAuth.instance.currentUser!.uid;
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Future<void> saveFcmToken() async {
  //   final token = await _messaging.getToken();
  //   if (token != null) {
  //     await _firestore.collection('User').doc(userId).update({
  //       'fcmToken': token,
  //     });
  //   }
  // }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String get userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user signed in');
    return user.uid;
  }

  Future<void> saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('User').doc(user.uid).update({
        'fcmToken': token,
      });
    }
  }

  Stream<List<BookingModel>> driverBookingsLive({int minutesWindow = 10}) {
    return Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('Booking')
          .where('driverId', isEqualTo: userId)
          .where('end',
              isGreaterThanOrEqualTo: now.subtract(const Duration(hours: 1)))
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromDoc(doc))
          .where((booking) {
        final minutesLeft = booking.end.difference(now).inMinutes;
        final isEndingSoon = minutesLeft <= minutesWindow && minutesLeft > -5;
        final isOverstaying =
            now.isAfter(booking.end) && booking.checkout == null;
        final overstayNotPaid = !(booking.overstayFeePaid ?? false);
        return booking.checkout == null &&
            (isEndingSoon || (isOverstaying && overstayNotPaid));
      }).toList();
    });
  }

  Stream<List<BookingModel>> hostBookingsLive({int minutesWindow = 10}) {
    return Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('Booking')
          .where('hostId', isEqualTo: userId)
          .where('end',
              isGreaterThanOrEqualTo: now.subtract(const Duration(hours: 1)))
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromDoc(doc))
          .where((booking) {
        final minutesLeft = booking.end.difference(now).inMinutes;
        final isEndingSoon = minutesLeft <= minutesWindow && minutesLeft > -5;
        final isOverstaying =
            now.isAfter(booking.end) && booking.checkout == null;
        final overstayNotPaid = !(booking.overstayFeePaid ?? false);
        return booking.checkout == null &&
            (isEndingSoon || (isOverstaying && overstayNotPaid));
      }).toList();
    });
  }

  Future<void> triggerTestNotification() async {
    try {
      final callable = _functions.httpsCallable('testNotify');
      final result = await callable.call(); // run function
      debugPrint('✅ Cloud Function result: ${result.data}');
    } catch (e) {
      debugPrint('❌ Error calling testNotify: $e');
    }
  }

  void listenToFcmMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received FCM message: ${message.notification?.title}');
      // Optionally show a local notification using flutter_local_notifications
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('User tapped notification: ${message.notification?.title}');
      // Optionally navigate to the NotificationScreen or BookingScreen
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Make sure Firebase is initialized
  await Firebase.initializeApp();
  print('Background FCM message: ${message.notification?.title}');
}
