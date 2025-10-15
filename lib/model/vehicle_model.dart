import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String userId;
  final String plateNumber;
  final String description;

  VehicleModel({
    required this.id,
    required this.userId,
    required this.plateNumber,
    required this.description,
  });

  factory VehicleModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'plateNumber': plateNumber,
      'description': description,
    };
  }
}
