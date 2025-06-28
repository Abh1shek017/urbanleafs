import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/attendance_status_provider.dart' as asp;
// import '../../viewmodels/attendance_viewmodel.dart' as vm;
import 'package:urbanleafs/utils/capitalize.dart';

class DailyAttendanceShiftPage extends ConsumerWidget {
  final String shift;
  const DailyAttendanceShiftPage({super.key, required this.shift});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final allUsersAsync = ref.watch(allUsersStreamProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                '${shift.capitalize()} Shift',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: currentUserAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading user: $e')),
                data: (currentUser) {
                  final userId = currentUser?.id ?? '';

                  return allUsersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error loading workers: $e')),
                    data: (workers) {
                      if (workers.isEmpty) {
                        return const Center(child: Text("No workers found."));
                      }

                      return ListView.separated(
                        itemCount: workers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final worker = workers[index];
                          final status = ref.watch(
                            asp.attendanceStatusProvider(
                              asp.AttendanceStatusParams(
                                userId: worker.id,
                                shift: shift,
                              ),
                            ),
                          );
                          final notifier = ref.read(
                            asp
                                .attendanceStatusProvider(
                                  asp.AttendanceStatusParams(
                                    userId: worker.id,
                                    shift: shift,
                                  ),
                                )
                                .notifier,
                          );

                          final initial = worker.username.isNotEmpty
                              ? worker.username[0].toUpperCase()
                              : '?';

                          Color borderColor = Colors.grey;
                          if (status == AppConstants.statusPresent) {
                            borderColor = Colors.green;
                          } else if (status == AppConstants.statusAbsent) {
                            borderColor = Colors.red;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: borderColor, width: 2),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[300],
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          worker.username,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 8,
                                          children: [
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth:
                                                    (constraints.maxWidth -
                                                        100) /
                                                    2,
                                              ),
                                              child: ElevatedButton.icon(
                                                onPressed: status.isNotEmpty
                                                    ? null
                                                    : () async {
                                                        await ref
                                                            .read(
                                                              attendanceRepositoryProvider,
                                                            )
                                                            .markAttendance(
                                                              userId: worker.id,
                                                              shift: shift,
                                                              status: AppConstants
                                                                  .statusPresent,
                                                              markedBy: userId,
                                                            );
                                                        notifier.updateStatus(
                                                          AppConstants
                                                              .statusPresent,
                                                        );
                                                      },
                                                icon: const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                label: const Text(
                                                  "Present",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      status ==
                                                          AppConstants
                                                              .statusPresent
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth:
                                                    (constraints.maxWidth -
                                                        100) /
                                                    2,
                                              ),
                                              child: ElevatedButton.icon(
                                                onPressed: status.isNotEmpty
                                                    ? null
                                                    : () async {
                                                        await ref
                                                            .read(
                                                              attendanceRepositoryProvider,
                                                            )
                                                            .markAttendance(
                                                              userId: worker.id,
                                                              shift: shift,
                                                              status: AppConstants
                                                                  .statusAbsent,
                                                              markedBy: userId,
                                                            );
                                                        notifier.updateStatus(
                                                          AppConstants
                                                              .statusAbsent,
                                                        );
                                                      },
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                label: const Text(
                                                  "Absent",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      status ==
                                                          AppConstants
                                                              .statusAbsent
                                                      ? Colors.red
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
