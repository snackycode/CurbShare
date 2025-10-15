import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ParklotModel {
  final String id;
  final String hostId;
  final String? img;
  final String name;
  final GeoPoint location;
  final String desc;
  final int capacity;
  final double hourlyRate;
  final double dailyRate;
  final double monthlyRate;
  final DateTime? availableFrom;
  final DateTime? closeBefore;
  final bool echarge;
  int occupied;
  final DateTime? createdAt;

  ParklotModel({
    required this.id,
    required this.hostId,
    required this.img,
    required this.name,
    required this.location,
    required this.desc,
    required this.capacity,
    required this.hourlyRate,
    required this.dailyRate,
    required this.monthlyRate,
    required this.availableFrom,
    required this.closeBefore,
    required this.echarge,
    required this.occupied,
    this.createdAt,
  });

  // Create from Firestore document
  factory ParklotModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ParklotModel(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      img: data['img'],
      name: data['name'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      desc: data['desc'] ?? '',
      capacity: data['capacity'] ?? 0,
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      dailyRate: (data['dailyRate'] ?? 0).toDouble(),
      monthlyRate: (data['monthlyRate'] ?? 0).toDouble(),
      availableFrom: data['availableFrom'] != null
          ? (data['availableFrom'] as Timestamp).toDate()
          : null,
      closeBefore: data['closeBefore'] != null
          ? (data['closeBefore'] as Timestamp).toDate()
          : null,
      echarge: data['echarge'] is bool ? data['echarge'] : false,
      occupied:
          data['occupied'] != null ? (data['occupied'] as num).toInt() : 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to map to save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'img': img,
      'name': name,
      'location': location,
      'desc': desc,
      'capacity': capacity,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'monthlyRate': monthlyRate,
      'availableFrom': availableFrom,
      'closeBefore': closeBefore,
      'echarge': echarge,
      'occupied': occupied,
      'createdAt': createdAt,
    };
  }

  // Helper getters if you need lat/lng separately
  double get lat => location.latitude;
  double get lng => location.longitude;

  /// Helper method to convert Base64 string to Uint8List
  Uint8List? get imageBytes => img != null ? base64Decode(img!) : null;

  /// Helper widget to display the image
  Widget? get imageWidget =>
      imageBytes != null ? Image.memory(imageBytes!, fit: BoxFit.cover) : null;
}
