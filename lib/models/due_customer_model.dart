class CustomerWithDue {
  final String name;
  final String phone;
  final String? profileImageUrl;
  final String? shopName;
  final List<Map<String, dynamic>> dueOrders;
  final List<Map<String, dynamic>> allOrders;
  final List<Map<String, dynamic>> payments;
  final double totalDue;
  final String address;

  CustomerWithDue({
    required this.name,
    required this.phone,
    this.profileImageUrl,
    this.shopName,
    required this.dueOrders,
    required this.totalDue,
    required this.address,
    required this.allOrders,
    required this.payments,
  });

  // Factory to map Firestore document to class
  factory CustomerWithDue.fromMap(Map<String, dynamic> data) {
    return CustomerWithDue(
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      profileImageUrl: data['profileUrl'],
      shopName: data['shopName'], // <-- Make sure this matches Firestore field
      dueOrders: List<Map<String, dynamic>>.from(data['dueOrders'] ?? []),
      totalDue: (data['totalDue'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      allOrders: List<Map<String, dynamic>>.from(data['allOrders'] ?? []),
      payments: List<Map<String, dynamic>>.from(data['payments'] ?? []),
    );
  }
}
