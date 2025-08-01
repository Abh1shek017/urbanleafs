import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

DateTime getOrderTime(dynamic orderTime) {
  if (orderTime is Timestamp) return orderTime.toDate();
  if (orderTime is DateTime) return orderTime;
  return DateTime.now();
}

class CustomerDetailScreen extends StatefulWidget {
  final dynamic customer;
  final List<Map<String, dynamic>> payments;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
    required this.payments,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  String? selectedYear;
  String? selectedMonth;
  String paymentFilter = 'All';
  String sortOption = 'Latest First';

  final List<String> yearOptions = ['2024', '2025'];
  final List<String> monthOptions = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> paymentStatusOptions = [
    'All',
    'Paid',
    'Unpaid',
    'Partially Paid',
  ];

  late List<Map<String, dynamic>> filteredOrders; 
  late List<Map<String, dynamic>> filteredPayments;
  double totalAmount = 0;
  double totalPaid = 0;
  double totalDue = 0;

  @override
  void initState() {
    super.initState();
    applyFilters();
  }

void applyFilters() {
  List<Map<String, dynamic>> allOrders = [...widget.customer.allOrders];
  List<Map<String, dynamic>> allPayments = [...widget.payments];

  // Apply filters to orders
  filteredOrders = [...allOrders];
  if (selectedYear != null && selectedMonth != null) {
    filteredOrders = filteredOrders.where((order) {
      final orderDate = getOrderTime(order['orderTime']);
      return orderDate.year.toString() == selectedYear &&
          orderDate.month == (monthOptions.indexOf(selectedMonth!) + 1);
    }).toList();
  }

  if (paymentFilter != 'All') {
    filteredOrders = filteredOrders.where((order) {
      final status = (order['paymentStatus'] ?? '').toString().toLowerCase();
      return status == paymentFilter.toLowerCase();
    }).toList();
  }

  filteredOrders.sort((a, b) {
    final aTime = getOrderTime(a['orderTime']);
    final bTime = getOrderTime(b['orderTime']);
    return sortOption == 'Latest First'
        ? bTime.compareTo(aTime)
        : aTime.compareTo(bTime);
  });

  // Apply year/month filter to payments
  filteredPayments = allPayments;
  if (selectedYear != null && selectedMonth != null) {
    filteredPayments = filteredPayments.where((payment) {
      final time = getOrderTime(payment['receivedTime'] ?? payment['timestamp']);
      return time.year.toString() == selectedYear &&
          time.month == (monthOptions.indexOf(selectedMonth!) + 1);
    }).toList();
  }

  // You can also sort payments if needed (optional)
  filteredPayments.sort((a, b) {
    final aTime = getOrderTime(a['receivedTime'] ?? a['timestamp']);
    final bTime = getOrderTime(b['receivedTime'] ?? b['timestamp']);
    return bTime.compareTo(aTime);
  });

  // Totals (Paid includes only filtered payments)
  totalAmount = filteredOrders.fold(
    0.0,
    (sum, order) => sum + (order['totalAmount'] ?? 0).toDouble(),
  );
  totalPaid = filteredPayments.fold(
    0.0,
    (sum, payment) => sum + (payment['amount'] ?? 0).toDouble(),
  );
  totalDue = totalAmount - totalPaid;
}


Widget _buildScrollableTab(Widget child) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: child,
  );
}

@override
Widget build(BuildContext context) {
  final customer = widget.customer;

  return DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: Column(
        children: [
          _buildFilters(),           // ✅ Scrollable with rest
          _buildHeader(customer),     // ✅ Static content (not scrollable)
          _buildSummary(),           // ✅ Scrollable with rest
          const Divider(),
          Expanded(
            child: TabBarView(
              children: [
                _buildScrollableTab(_buildOrderSection()),
                _buildScrollableTab(_buildPaymentSection()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const TabBar(
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(text: 'Orders'),
          Tab(text: 'Payments'),
        ],
      ),
    ),
  );
}

  Widget _buildHeader(dynamic customer) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
        color: const Color(0xFFEFEFEF), // slightly darker background
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              customer.profileImageUrl?.isNotEmpty == true
                  ? CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(customer.profileImageUrl!),
                    )
                  : const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
              const SizedBox(height: 8),
              Text(
                customer.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Phone section
                  GestureDetector(
                    onTap: () async {
                      final Uri phoneUri = Uri(
                        scheme: 'tel',
                        path: customer.phone,
                      );
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          customer.phone,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Address section
                  Row(
                    children: [
                      const Icon(Icons.home, size: 18, color: Colors.grey),
                      const SizedBox(width: 4), // reduce gap if needed
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          customer.address,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(color: Colors.black54)),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
          onChanged: onChanged,
          items: items
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: const Color.fromARGB(255, 172, 227, 161), // Dark background
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF), // Light background for filter bar
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterDropdown(
                label: "Year",
                value: selectedYear,
                items: yearOptions,
                onChanged: (val) => setState(() {
                  selectedYear = val;
                  selectedMonth = null;
                  applyFilters();
                }),
              ),
              const SizedBox(width: 12),
              if (selectedYear != null)
                _buildFilterDropdown(
                  label: "Month",
                  value: selectedMonth,
                  items: monthOptions,
                  onChanged: (val) => setState(() {
                    selectedMonth = val;
                    applyFilters();
                  }),
                ),
              if (selectedYear != null) const SizedBox(width: 12),
              _buildFilterDropdown(
                label: "Sort",
                value: sortOption,
                items: ['Latest First', 'Oldest First'],
                onChanged: (val) => setState(() {
                  sortOption = val!;
                  applyFilters();
                }),
              ),
              const SizedBox(width: 10),
              _buildFilterDropdown(
                label: "Payment",
                value: paymentFilter,
                items: paymentStatusOptions,
                onChanged: (val) => setState(() {
                  paymentFilter = val!;
                  applyFilters();
                }),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => setState(() {
                  selectedYear = null;
                  selectedMonth = null;
                  sortOption = 'Latest First';
                  paymentFilter = 'All';
                  applyFilters();
                }),
                icon: const Icon(Icons.clear, size: 18, color: Colors.black87),
                label: const Text(
                  "Clear",
                  style: TextStyle(color: Colors.black87),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(
    IconData icon,
    String label,
    double amount,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              "₹${amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 212, 209, 209), // Light background
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryTile(
              Icons.receipt_long,
              "Total",
              totalAmount,
              Colors.black87,
            ),
            _buildSummaryTile(
              Icons.check_circle,
              "Paid",
              totalPaid,
              Colors.green,
            ),
            _buildSummaryTile(Icons.error, "Due", totalDue, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSection() {
    if (filteredOrders.isEmpty) {
      return const Center(child: Text('No orders found.'));
    }

    return Column(
      children: List.generate(filteredOrders.length, (index) {
        final order = filteredOrders[index];
        final time = getOrderTime(order['orderTime']);
        final paid = (order['amountPaid'] ?? 0).toDouble();
        final total = (order['totalAmount'] ?? 0).toDouble();
        final due = total - paid;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text('₹${total.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paid: ₹${paid.toStringAsFixed(2)}'),
                Text('Due: ₹${due.toStringAsFixed(2)}'),
                Text(DateFormat('dd MMM yyyy').format(time)),
                Text('Status: ${order['paymentStatus'] ?? 'Unknown'}'),
              ],
            ),
          ),
        );
      }),
    );
  }
Widget _buildPaymentSection() {
  if (filteredPayments.isEmpty) {
    return const Center(child: Text('No payments found.'));
  }

  final payments = List<Map<String, dynamic>>.from(filteredPayments);

  payments.sort((a, b) {
    final aTime = getOrderTime(a['receivedTime'] ?? a['timestamp']);
    final bTime = getOrderTime(b['receivedTime'] ?? b['timestamp']);
    return bTime.compareTo(aTime);
  });

  return Column(
    children: List.generate(payments.length, (index) {
      final payment = payments[index];
      final amount = (payment['amount'] ?? 0).toDouble();
      final note = payment['note'];
      final receiver = payment['receivedBy'] ?? 'Unknown';
      final receivedTime = getOrderTime(
        payment['receivedTime'] ?? payment['timestamp'],
      );

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Icon(
            note != null ? Icons.flash_on : Icons.payments,
            color: note != null ? Colors.orange : Colors.blue,
          ),
          title: Text('₹${amount.toStringAsFixed(2)}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Received by: $receiver'),
              if (note != null) Text('Note: $note'),
              Text(
                'Date: ${DateFormat('dd MMM yyyy – hh:mm a').format(receivedTime)}',
              ),
            ],
          ),
        ),
      );
    }),
  );
}
}
