import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/vehicle_model.dart';
import 'package:curbshare/provider/userDoc.dart';
import 'package:curbshare/user/driver/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null) {
        setState(() {
          _isProcessing = true;
        });

        try {
          final data = jsonDecode(rawValue);
          final lotId = data['lotId'];
          final type = data['type'];
          if (type == "checkin") {
            _updateCheckIn(lotId);
          } else if (type == "checkout") {
            _updateCheckOut(lotId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("Invalid Qr Code"),
                  backgroundColor: Colors.blue),
            );
          }
          controller.stop();
          if (mounted) Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error reading QR: $e"),
                backgroundColor: Colors.blue),
          );
        }
      }
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateCheckIn(String lotId) async {
    final user = FirebaseAuth.instance.currentUser;
    print("Check-in for $lotId");
    if (user == null) return;
    final bookingQuery = await FirebaseFirestore.instance
        .collection("Booking")
        .where("lotId", isEqualTo: lotId)
        .where("checkin", isNull: true) // only active booking
        .limit(1)
        .get();

    if (bookingQuery.docs.isNotEmpty) {
      final bookingId = bookingQuery.docs.first.id;
      final userDoc = context.read<UserDoc>();
      final vehicleQuery = await FirebaseFirestore.instance
          .collection("Vehicle")
          .where("userId", isEqualTo: user.uid)
          .get();

      final vehicles =
          vehicleQuery.docs.map((doc) => VehicleModel.fromDoc(doc)).toList();
      if (vehicles.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No vehicles found. Please add a vehicle first.")),
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        return;
      }
      if (!mounted) return;
      final selectedVehicleName = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Select Vehicle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: vehicles.map((vehicle) {
                return ListTile(
                  title: Text(vehicle.plateNumber),
                  subtitle: Text(vehicle.description),
                  onTap: () => Navigator.pop(context, vehicle.plateNumber),
                );
              }).toList(),
            ),
          );
        },
      );

      await FirebaseFirestore.instance
          .collection("Booking")
          .doc(bookingId)
          .update({
        "checkin": DateTime.now(),
        "vehicleName": selectedVehicleName,
      });

      print("✅ Booking $bookingId checked in");
    } else {
      print("⚠️ No active booking found for $lotId");
    }
  }

  Future<void> _updateCheckOut(String lotId) async {
    print("Check-out for $lotId");

    final bookingQuery = await FirebaseFirestore.instance
        .collection("Booking")
        .where("lotId", isEqualTo: lotId)
        .where("checkin", isNotEqualTo: null)
        .where("checkout", isNull: true)
        .limit(1)
        .get();

    if (bookingQuery.docs.isNotEmpty) {
      final bookingId = bookingQuery.docs.first.id;

      await FirebaseFirestore.instance
          .collection("Booking")
          .doc(bookingId)
          .update({
        "checkout": DateTime.now(),
      });

      print("✅ Booking $bookingId checked out");
      final parkLotRef =
          FirebaseFirestore.instance.collection("ParkingLot").doc(lotId);
      await parkLotRef.update({
        "occupied": FieldValue.increment(-1),
      });
    } else {
      print("⚠️ No active booking found for $lotId");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          _buildFloatingBackButton(context),
        ],
      ),
    );
  }

  Widget _buildFloatingBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Colors.white,
              Color(0xFF77BBFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF004991)),
          onPressed: () => Navigator.pop(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          padding: EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }
}
