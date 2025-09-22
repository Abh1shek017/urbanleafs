import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? profileImageUrl;
  final String? gstNumber; // optional
  final String shopName;   // <-- new optional field
  final String addedBy;
  final Timestamp createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.profileImageUrl,
    this.gstNumber,
    required this.shopName,          // <-- initialize
    required this.addedBy,
    required this.createdAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      profileImageUrl: map['profileUrl'], // keep optional
      gstNumber: map['gstNumber'],        // optional
      shopName: map['shopName'],          // <-- read from map
      addedBy: map['addedBy'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
  return {
    'name': name,
    'shopName': shopName,
    'phone': phone,
    'address': address,
    if (gstNumber != null && gstNumber!.isNotEmpty) 'gstNumber': gstNumber,
    'profileUrl': profileImageUrl,
    'addedBy': addedBy,
    'createdAt': createdAt,
  };
}

}
