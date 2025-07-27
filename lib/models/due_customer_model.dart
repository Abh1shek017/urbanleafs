class CustomerWithDue {
  final String name;
  final String phone;
  late String? profileImageUrl;
  final List<Map<String, dynamic>> dueOrders;
  final List<Map<String, dynamic>> allOrders;
  final double totalDue;
  final String address;

  CustomerWithDue({
    required this.name,
    required this.phone,
    this.profileImageUrl,
    required this.dueOrders,
    required this.totalDue,
    required this.address,
    required this.allOrders,
  });
}
