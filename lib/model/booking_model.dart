import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookingModel {
  final String id;
  final String lotId;
  final String driverId;
  final String hostId;
  final DateTime start;
  final DateTime end;
  final double budget;
  final LatLng? searchLocation; // picked location
  final String reservationType; // "hourly" | "monthly"
  final String? paymentIntentId; // Stripe PaymentIntent
  final String? paymentStatus; // 'requires_payment_method', 'succeeded', etc.
  final DateTime? checkin;
  final DateTime? checkout;
  final String? vehicleName;
  final bool notifiedDriver;
  final bool notifiedHost;
  final bool overstayFeePaid;
  final double? overstayFeeAmount;

  BookingModel({
    required this.id,
    required this.lotId,
    required this.driverId,
    required this.hostId,
    required this.start,
    required this.end,
    required this.budget,
    this.searchLocation,
    this.reservationType = "hourly",
    this.paymentIntentId,
    this.paymentStatus,
    this.checkin,
    this.checkout,
    this.vehicleName,
    this.notifiedDriver = false,
    this.notifiedHost = false,
    this.overstayFeePaid = false,
    this.overstayFeeAmount = 0,
  });

  factory BookingModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    LatLng? location;
    if (data['searchLocation'] != null && data['searchLocation'] is GeoPoint) {
      final geo = data['searchLocation'] as GeoPoint;
      location = LatLng(geo.latitude, geo.longitude);
    }

    return BookingModel(
      id: doc.id,
      lotId: data['lotId'] ?? '',
      driverId: data['driverId'] ?? '',
      hostId: data['hostId'] ?? '',
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
      budget: (data['budget'] ?? 0).toDouble(),
      searchLocation: location,
      reservationType: data['reservationType'] ?? 'hourly',
      paymentIntentId: data['paymentIntentId'],
      paymentStatus: data['paymentStatus'],
      checkin: data['checkin'] != null
          ? (data['checkin'] as Timestamp).toDate()
          : null,
      checkout: data['checkout'] != null
          ? (data['checkout'] as Timestamp).toDate()
          : null,
      vehicleName: data['vehicleName'] as String?,
      notifiedDriver: data['notifiedDriver'] ?? false,
      notifiedHost: data['notifiedHost'] ?? false,
      overstayFeePaid: data['overstayFeePaid'] ?? false,
      overstayFeeAmount: (data['overstayFeeAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lotId': lotId,
      'driverId': driverId,
      'hostId': hostId,
      'start': start,
      'end': end,
      'budget': budget,
      'reservationType': reservationType,
      if (searchLocation != null)
        'searchLocation':
            GeoPoint(searchLocation!.latitude, searchLocation!.longitude),
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (checkin != null) 'checkin': checkin,
      if (checkout != null) 'checkout': checkout,
      if (vehicleName != null) 'vehicleName': vehicleName,
      'notifiedDriver': notifiedDriver,
      'notifiedHost': notifiedHost,
      'overstayFeePaid': overstayFeePaid,
      'overstayFeeAmount': overstayFeeAmount,
    };
  }
}
