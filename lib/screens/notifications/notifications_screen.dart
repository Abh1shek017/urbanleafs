import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';

// StreamProvider to listen to all notifications across subcollections
final allNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final types = ['orders', 'expenses', 'payments', 'inventory', 'attendance'];

  final streams = types.map((type) {
    return firestore
        .collection('notifications')
        .doc(type)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return NotificationModel(
              id: doc.id,
              title: data['title'] ?? '',
              body: data['message'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              type: type,
              isRead: data['isRead'] ?? false,
            );
          }).toList(),
        );
  });

  return Stream<List<NotificationModel>>.multi((controller) {
    final List<List<NotificationModel>> combined = List.generate(
      types.length,
      (_) => [],
    );
    final subscriptions = <StreamSubscription>[];

    for (var i = 0; i < streams.length; i++) {
      final sub = streams.elementAt(i).listen((data) {
        combined[i] = data;
        final all = combined.expand((e) => e).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        controller.add(all.take(10).toList());
      });
      subscriptions.add(sub);
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };
  });
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _loadingMarkAll = false;

  // Get color based on type
  Color _getBgColor(String? type, bool isRead) {
    Color base;
    switch (type) {
      case 'orders':
        base = Colors.green.shade100;
        break;
      case 'expenses':
        base = Colors.red.shade100;
        break;
      case 'payments':
        base = Colors.teal.shade100;
        break;
      case 'inventory':
        base = Colors.orange.shade100;
        break;
      default:
        base = Colors.grey.shade200;
    }
    return isRead ? base.withOpacity(0.4) : base;
  }

  // Group by Today / Yesterday / Date
  Map<String, List<NotificationModel>> _groupByDate(
    List<NotificationModel> notifications,
  ) {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();

    for (var n in notifications) {
      final date = n.timestamp;
      String key;
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        key = 'Today';
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1) {
        key = 'Yesterday';
      } else {
        key = DateFormat('d MMM yyyy').format(date);
      }
      grouped.putIfAbsent(key, () => []).add(n);
    }
    return grouped;
  }

  // Mark all as read
  Future<void> _markAllAsRead() async {
    setState(() => _loadingMarkAll = true);

    final firestore = FirebaseFirestore.instance;
    final types = ['orders', 'expenses', 'payments', 'inventory'];
    final batch = firestore.batch();

    for (final type in types) {
      final query = await firestore
          .collection('notifications')
          .doc(type)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
    setState(() => _loadingMarkAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(allNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          _loadingMarkAll
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  tooltip: "Mark all as read",
                  onPressed: _markAllAsRead,
                ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text("Error loading notifications")),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text("No notifications", style: TextStyle(fontSize: 16)),
            );
          }

          final grouped = _groupByDate(notifications);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              final date = entry.key;
              final items = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...items.map((notification) {
                    final bgColor = _getBgColor(
                      notification.type,
                      notification.isRead,
                    );
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.body),
                            const SizedBox(height: 4),
                            Text(
                              timeago.format(notification.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (!notification.isRead) {
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(notification.type)
                                .collection('items')
                                .doc(notification.id)
                                .update({'isRead': true});
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
