import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.imageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  /// ✅ Properly typed and complete
  WorkerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return WorkerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory WorkerModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkerModel.fromMap(data, id: doc.id);
  }
}
