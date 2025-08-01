 import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to safely parse orderTime from dynamic input.
DateTime getOrderTime(dynamic orderTime) {
  if (orderTime is Timestamp) {
    return orderTime.toDate();
  } else if (orderTime is DateTime) {
    return orderTime;
  }
  return DateTime.now();
}

void showCustomerDetailBottomSheet(
  BuildContext context,
  dynamic customer,
  List<Map<String, dynamic>> payments,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
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

            List<Map<String, dynamic>> allOrders = [...customer.allOrders];
            List<Map<String, dynamic>> filteredOrders = [...allOrders];

            double totalAmount = 0;
            double totalPaid = 0;
            double totalDue = 0;

            void applyFilters() {
              filteredOrders = [...customer.allOrders];

              if (selectedYear != null && selectedMonth != null) {
                filteredOrders = filteredOrders.where((order) {
                  final orderDate = getOrderTime(order['orderTime']);
                  return orderDate.year.toString() == selectedYear &&
                      orderDate.month ==
                          (monthOptions.indexOf(selectedMonth!) + 1);
                }).toList();
              }

              if (paymentFilter != 'All') {
                filteredOrders = filteredOrders.where((order) {
                  final status = (order['paymentStatus'] ?? '')
                      .toString()
                      .toLowerCase();
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

              totalAmount = 0;
              totalPaid = 0;
              for (var order in filteredOrders) {
                totalAmount += (order['totalAmount'] ?? 0).toDouble();
              }
              totalPaid = payments.fold(
                0.0,
                (sum, payment) => sum + ((payment['amount'] ?? 0).toDouble()),
              );
              totalDue = totalAmount - totalPaid;
            }

            applyFilters();

            return StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          Center(
                            child: customer.profileImageUrl?.isNotEmpty == true
                                ? CircleAvatar(
                                    radius: 40,
                                    backgroundImage: NetworkImage(
                                      customer.profileImageUrl!,
                                    ),
                                  )
                                : const CircleAvatar(
                                    radius: 40,
                                    child: Icon(Icons.person, size: 40),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                child: Text(
                                  "📞 ${customer.phone}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueAccent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "🏠 ${customer.address}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              DropdownButton<String>(
                                hint: const Text("Select Year"),
                                value: selectedYear,
                                items: yearOptions.map((year) {
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedYear = value;
                                    selectedMonth = null;
                                    applyFilters();
                                  });
                                },
                              ),
                              if (selectedYear != null)
                                DropdownButton<String>(
                                  hint: const Text("Select Month"),
                                  value: selectedMonth,
                                  items: monthOptions.map((month) {
                                    return DropdownMenuItem(
                                      value: month,
                                      child: Text(month),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedMonth = value;
                                      applyFilters();
                                    });
                                  },
                                ),
                              DropdownButton<String>(
                                value: sortOption,
                                items: ['Latest First', 'Oldest First'].map((
                                  option,
                                ) {
                                  return DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    sortOption = value!;
                                    applyFilters();
                                  });
                                },
                              ),
                              DropdownButton<String>(
                                value: paymentFilter,
                                items: paymentStatusOptions.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    paymentFilter = value!;
                                    applyFilters();
                                  });
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.clear),
                                label: const Text("Clear Filters"),
                                onPressed: () {
                                  setState(() {
                                    selectedYear = null;
                                    selectedMonth = null;
                                    paymentFilter = 'All';
                                    sortOption = 'Latest First';
                                    applyFilters();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceAround,
                            children: [
                              Text(
                                '🧾 Total: ₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '✅ Paid: ₹${totalPaid.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                              Text(
                                '❌ Due: ₹${totalDue.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              labelColor: Colors.blue,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.blue,
                              tabs: [
                                Tab(text: 'Orders'),
                                Tab(text: 'Payments'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  ListView.builder(
                                    controller: scrollController,
                                    itemCount: filteredOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = filteredOrders[index];
                                      final orderTime = getOrderTime(
                                        order['orderTime'],
                                      );
                                      final paid = (order['amountPaid'] ?? 0)
                                          .toDouble();
                                      final total = (order['totalAmount'] ?? 0)
                                          .toDouble();
                                      final due = total - paid;
                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            '₹${total.toStringAsFixed(2)}',
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Paid: ₹${paid.toStringAsFixed(2)}',
                                              ),
                                              Text(
                                                'Due: ₹${due.toStringAsFixed(2)}',
                                              ),
                                              Text(
                                                DateFormat(
                                                  'dd MMM yyyy',
                                                ).format(orderTime),
                                              ),
                                              Text(
                                                'Status: ${order['paymentStatus'] ?? 'Unknown'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  payments.isEmpty
                                      ? const Center(
                                          child: Text('No payments found.'),
                                        )
                                      : (() {
                                          payments.sort((a, b) {
                                            final tsA =
                                                a['receivedTime'] ??
                                                a['timestamp'];
                                            final tsB =
                                                b['receivedTime'] ??
                                                b['timestamp'];

                                            final dateA = tsA is Timestamp
                                                ? tsA.toDate()
                                                : (tsA is DateTime
                                                      ? tsA
                                                      : DateTime.now());
                                            final dateB = tsB is Timestamp
                                                ? tsB.toDate()
                                                : (tsB is DateTime
                                                      ? tsB
                                                      : DateTime.now());

                                            return dateB.compareTo(
                                              dateA,
                                            ); // Descending order
                                          });

                                          return ListView.builder(
                                            controller: scrollController,
                                            itemCount: payments.length,
                                            itemBuilder: (context, index) {
                                              final payment = payments[index];
                                              final amount =
                                                  (payment['amount'] ?? 0)
                                                      .toDouble();
                                              final note = payment['note'];
                                              final receiver =
                                                  payment['receivedBy'] ??
                                                  'Unknown';
                                              final timestamp =
                                                  payment['receivedTime'] ??
                                                  payment['timestamp'];
                                              final receivedTime =
                                                  timestamp is Timestamp
                                                  ? timestamp.toDate()
                                                  : (timestamp is DateTime
                                                        ? timestamp
                                                        : DateTime.now());
                                              final isAutoPayment =
                                                  note != null &&
                                                  note.toString().isNotEmpty;

                                              return Card(
                                                child: ListTile(
                                                  leading: Icon(
                                                    isAutoPayment
                                                        ? Icons.flash_on
                                                        : Icons.payments,
                                                    color: isAutoPayment
                                                        ? Colors.orange
                                                        : Colors.blue,
                                                  ),
                                                  title: Text(
                                                    '₹${amount.toStringAsFixed(2)}',
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Received by: $receiver',
                                                      ),
                                                      Text(
                                                        isAutoPayment
                                                            ? 'Note: $note'
                                                            : 'Manual payment',
                                                      ),
                                                      Text(
                                                        'Date: ${DateFormat('dd MMM yyyy – hh:mm a').format(receivedTime)}',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        })(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }