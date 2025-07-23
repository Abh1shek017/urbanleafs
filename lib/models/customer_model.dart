import 'package:cloud_firestore/cloud_firestore.dart';
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? profileImageUrl;
  final String? gstNumber; // <-- now optional
  final String addedBy;
  final Timestamp createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.profileImageUrl,
    this.gstNumber, // <-- not required
    required this.addedBy,
    required this.createdAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      profileImageUrl: map['profileUrl'] ?? '',
      gstNumber: map['gstNumber'], // no default
      addedBy: map['addedBy'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'profileUrl': profileImageUrl,
      if (gstNumber != null && gstNumber!.isNotEmpty) 'gstNumber': gstNumber,
      'addedBy': addedBy,
      'createdAt': createdAt,
    };
  }
}
