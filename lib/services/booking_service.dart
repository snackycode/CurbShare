// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:curbshare/model/booking_model.dart';
// import 'package:curbshare/model/parklot_model.dart';

// class BookingService {
//   final CollectionReference _bookingCollection =
//       FirebaseFirestore.instance.collection('Booking');

//   /// Check if a lot is available for the selected period
//   Future<bool> isAvailable({
//     required String lotId,
//     required DateTime start,
//     required DateTime end,
//   }) async {
//     final snapshot = await _bookingCollection
//         .where('lotId', isEqualTo: lotId)
//         .where('start', isLessThan: end)
//         .where('end', isGreaterThan: start)
//         .orderBy('start') // 👈 add ordering
//         .orderBy('end') // 👈 add ordering
//         .get();

//     return snapshot.docs.isEmpty;
//   }

//   /// Create a booking
//   Future<void> createBooking(
//       {required ParklotModel lot,
//       required String driverId,
//       required DateTime start,
//       required DateTime end,
//       required double budget}) async {
//     await _bookingCollection.add({
//       'lotId': lot.id,
//       'driverId': driverId,
//       'start': Timestamp.fromDate(start),
//       'end': Timestamp.fromDate(end),
//       'budget': budget,
//       'createdAt': FieldValue.serverTimestamp(),
//     });
//   }

//   /// Fetch bookings for a driver (optional)
//   Future<List<BookingModel>> fetchBookingsByDriver(String driverId) async {
//     final snapshot =
//         await _bookingCollection.where('driverId', isEqualTo: driverId).get();

//     return snapshot.docs
//         .map((doc) => BookingModel(
//               lotId: doc['lotId'],
//               driverId: doc['driverId'],
//               start: (doc['start'] as Timestamp).toDate(),
//               end: (doc['end'] as Timestamp).toDate(),
//               budget: (doc['budget'] as num).toDouble(),
//               id: '',
//             ))
//         .toList();
//   }
// }
