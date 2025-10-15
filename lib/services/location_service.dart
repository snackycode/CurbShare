import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final CollectionReference _lotsCollection =
      FirebaseFirestore.instance.collection('ParkingLot');

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<ParklotModel>> fetchAllLots() async {
    final snapshot = await _lotsCollection.get();
    print('Total docs fetched: ${snapshot.docs.length}'); // <-- add this
    for (var doc in snapshot.docs) {
      print('Lot: ${doc.data()}'); // <-- see document fields
    }
    return snapshot.docs.map((doc) => ParklotModel.fromDoc(doc)).toList();
  }

  /// Filter lots by availability + proximity

  Future<List<ParklotModel>> getFilteredLots({
    required List<ParklotModel> allLots,
    required DateTime start,
    required DateTime end,
    required LatLng userPos,
    int? minCapacity,
    RangeValues? priceRange,
    double? radiusMeters,
    String? bookingType,
    bool?
        echarge, // optional: true = only echarge, false = no echarge, null = any
  }) async {
    final allLots = await fetchAllLots();
    print("=== getFilteredLots ===");
    print("Total lots before filtering: ${allLots.length}");

    // 1️⃣ Availability filter
    final available = allLots.where((lot) {
      final from = lot.availableFrom;
      final to = lot.closeBefore;
      if (from == null || to == null) return true;
      // return from.isBefore(start) && to.isAfter(end);
      return !from.isAfter(start) && !to.isBefore(end);
    }).toList();
    print("After availability filter: ${available.length}");
    for (var lot in available) {
      print(" - ${lot.name}");
    }

    final typeFiltered = available.where((lot) {
      switch (bookingType) {
        // _bookingType is a String
        case 'hourly':
          return lot.hourlyRate > 0;
        case 'daily':
          return lot.dailyRate > 0;
        case 'monthly':
          return lot.monthlyRate > 0;
        default:
          return false;
      }
    }).toList();

    final nearby = (radiusMeters != null)
        ? typeFiltered.where((lot) {
            final dist = Geolocator.distanceBetween(
              userPos.latitude,
              userPos.longitude,
              lot.lat,
              lot.lng,
            );
            // Debug print
            print("User Pos: (${userPos.latitude}, ${userPos.longitude})");
            print("Lot ${lot.name} Pos: (${lot.lat}, ${lot.lng})");
            print("Distance to Lot ${lot.name}: ${dist.toStringAsFixed(1)} m");
            return dist <= radiusMeters;
          }).toList()
        : typeFiltered;
    print("After radius filter: ${nearby.length}");
    for (var lot in nearby) {
      print(" - ${lot.name}");
    }

    final capacityFiltered = (minCapacity != null)
        ? nearby
            .where((lot) => (lot.capacity - lot.occupied) >= minCapacity)
            .toList()
        : nearby;
    print("After capacity filter: ${capacityFiltered.length}");
    for (var lot in capacityFiltered) {
      print(" - ${lot.name}");
    }

    // 4️⃣ Price filter
    final priceFiltered = (priceRange != null)
        ? capacityFiltered.where((lot) {
            final price = calculatePrice(
              lot: lot,
              bookingType: bookingType,
              start: start,
              end: end,
            );
            return price >= priceRange.start && price <= priceRange.end;
          }).toList()
        : capacityFiltered;
    print("After price filter: ${priceFiltered.length}");
    for (var lot in priceFiltered) {
      print(" - ${lot.name}");
    }

    // 5️⃣ E-charge filter
    final echargeFiltered = (echarge != null)
        ? priceFiltered.where((lot) => lot.echarge == echarge).toList()
        : priceFiltered;
    print("After e-charge filter: ${echargeFiltered.length}");
    for (var lot in echargeFiltered) {
      print(" - ${lot.name}");
    }

    return echargeFiltered;
  }

  List<ParklotModel> nearbyLots(
      Position pos, double radiusMeters, List<ParklotModel> lots) {
    return lots.where((lot) {
      final dist = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, lot.lat, lot.lng);
      return dist <= radiusMeters;
    }).toList();
  }

  List<ParklotModel> availableLots(
      DateTime start, DateTime end, List<ParklotModel> lots) {
    return lots;
    // return lots.where((lot) {
    //   final from = lot.availableFrom;
    //   final to = lot.closeBefore;
    //   if (from == null || to == null) return true; // assume always available
    //   return from.isBefore(start) && to.isAfter(end);
    // }).toList();
  }

  Future<List<ParklotModel>> fetchNearbyAvailable(
      {required double radiusMeters,
      required DateTime start,
      required DateTime end}) async {
    final pos = await getCurrentPosition();
    final lots = await fetchAllLots();
    final nearby = nearbyLots(pos, radiusMeters, lots);
    return availableLots(start, end, nearby);
  }

  /// ------------------------
  /// New: Calculate total price
  /// ------------------------
  double calculatePrice(
      {required ParklotModel lot,
      required String? bookingType,
      DateTime? start,
      DateTime? end}) {
    if (bookingType == null) return 0;
    switch (bookingType) {
      case 'monthly':
        return lot.monthlyRate;
      case 'daily':
        if (start == null || end == null) return 0;
        final durationHours = end.difference(start).inMinutes / 60.0;
        final days = (durationHours / 24.0).ceil(); 
        return days * lot.dailyRate;
      case 'hourly':
        if (start == null || end == null) return 0;
        final hours = end.difference(start).inMinutes / 60.0;
        return (hours <= 0 ? 1 : hours.ceil()) * lot.hourlyRate;
      default:
        return 0;
    }
  }

  double calculateDistanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    final meters = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return meters / 1000.0;
  }

  /// Fetch lots based on booking type, start and end datetime
  Future<List<ParklotModel>> fetchingLots({
    required String bookingType,
    required DateTime start,
    DateTime? end,
  }) async {
    // Get current user position
    final userPos = await getCurrentPosition();

    // Use getFilteredLots with minimal filters for now
    final lots = await getFilteredLots(
      allLots: await fetchAllLots(),
      start: start,
      end: bookingType != 'monthly' ? end ?? start : start,
      userPos: LatLng(userPos.latitude, userPos.longitude),
      bookingType: bookingType,
    );

    print("fetchingLots: Found ${lots.length} lots for type $bookingType");
    return lots;
  }
}
