import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final double? balance;
  final List<VehicleModel> vehicles;
  final String? stripeCustomerId; // for driver (payer)
  final String? stripeAccountId; // for host (receiver)
  final String? cardLast4; // optional
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.balance,
    this.vehicles = const [],
    this.stripeCustomerId,
    this.stripeAccountId,
    this.cardLast4,
    this.fcmToken,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc,
      {List<VehicleModel> vehicles = const []}) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        role: data['role'] ?? '',
        balance: data['balance'] != null
            ? (data['balance'] as num).toDouble()
            : null,
        vehicles: vehicles,
        stripeAccountId: data['stripeAccountId'],
        stripeCustomerId: data['stripeCustomerId'],
        cardLast4: data['cardLast4'],
        fcmToken: data['fcmToken']);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'balance': balance ?? 0.0,
      if (stripeCustomerId != null) 'stripeCustomerId': stripeCustomerId,
      if (stripeAccountId != null) 'stripeAccountId': stripeAccountId,
      if (cardLast4 != null) 'cardLast4': cardLast4,
      if (fcmToken != null) 'fcmToken': fcmToken
    };
  }
}
