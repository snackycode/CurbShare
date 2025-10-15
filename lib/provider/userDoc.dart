import 'package:curbshare/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/vehicle_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserDoc extends ChangeNotifier {
  UserModel? _user;
  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;

  Future<void> fetchUser() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("User")
        .doc(authUser.uid)
        .get();

    // final vehicleQuery = await FirebaseFirestore.instance
    //     .collection("Vehicle")
    //     .where("userId", isEqualTo: authUser.uid)
    //     .get();

    // final vehicles =
    //     vehicleQuery.docs.map((doc) => VehicleModel.fromDoc(doc)).toList();

    // _user = UserModel.fromDoc(userDoc, vehicles: vehicles);
    _user = UserModel.fromDoc(userDoc);
    notifyListeners();
  }

  /// Add a new vehicle
  Future<void> addVehicle(String plate, String description) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    // Create a new document in Firestore
    // final vehicleRef =
    //     await FirebaseFirestore.instance.collection("Vehicle").add({
    //   "userId": authUser.uid,
    //   "plateNumber": plate,
    //   "description": description,
    //   "createdAt": FieldValue.serverTimestamp(),
    // });

    // // Create VehicleModel object
    // final newVehicle = VehicleModel(
    //   id: vehicleRef.id,
    //   userId: authUser.uid,
    //   plateNumber: plate,
    //   description: description,
    // );

    // Add to local user object
    // if (_user != null) {
    //   _user!.vehicles.add(newVehicle);
    //   notifyListeners();
    // }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("User")
          .doc(authUser.uid)
          .get();

      _user = UserModel.fromDoc(userDoc);
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch user: $e");
    }
  }

  /// Delete a vehicle
  // Future<void> deleteVehicle(String vehicleId) async {
  //   await FirebaseFirestore.instance
  //       .collection("Vehicle")
  //       .doc(vehicleId)
  //       .delete();

  //   if (_user != null) {
  //     _user!.vehicles.removeWhere((v) => v.id == vehicleId);
  //     notifyListeners();
  //   }
  // }

  void resetUser() {
    _user = null;
    notifyListeners();
  }
}
