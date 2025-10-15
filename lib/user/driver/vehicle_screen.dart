import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/vehicle_model.dart';
import 'package:curbshare/provider/userDoc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

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
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFF004991),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "My vehicles",
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: Color(0xFF004991),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFF004991)),
          onPressed: () => _showAddVehicleDialog(context),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (userId == null) {
      return const Center(
          child: Text("You must be logged in to view vehicles."));
    }

    return Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Vehicle")
              .where("userId", isEqualTo: userId)
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
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(text: "No vehicles yet. "),
                      TextSpan(
                        text: "Add Now",
                        style: const TextStyle(
                          color: Color(0xFF004991),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showAddVehicleDialog(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            final vehicles = snapshot.data!.docs
                .map((doc) => VehicleModel.fromDoc(doc))
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _buildVehicleCard(context, vehicle);
              },
            );
          },
        ));
  }

  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.directions_car, color: Color(0xFF004991)),
        title: Text(vehicle.plateNumber.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(vehicle.description),
        trailing: GestureDetector(
          onTap: () => _confirmDeleteVehicle(context, vehicle),
          child: const Icon(Icons.delete, color: Colors.redAccent),
        ),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final plateController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Vehicle",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004991),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: plateController,
                decoration: InputDecoration(
                  labelText: "Plate Number",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFF004991),
                ),
                onPressed: () async {
                  final plate = plateController.text.trim();
                  final desc = descController.text.trim();
                  if (plate.isEmpty || desc.isEmpty) return;

                  await FirebaseFirestore.instance.collection("Vehicle").add({
                    "userId": userId,
                    "plateNumber": plate,
                    "description": desc,
                  });

                  Navigator.pop(context);
                },
                child: const Text(
                  "Add",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteVehicle(BuildContext context, VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Delete Vehicle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete ${vehicle.plateNumber}?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("Vehicle")
                          .doc(vehicle.id)
                          .delete();
                      Navigator.pop(context);
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
