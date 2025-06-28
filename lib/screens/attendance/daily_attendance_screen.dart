import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urbanleafs/constants/app_constants.dart';
import 'package:urbanleafs/providers/worker_provider.dart';
import 'package:urbanleafs/providers/current_user_stream_provider.dart';
import 'package:urbanleafs/providers/attendance_provider.dart';
import 'package:urbanleafs/screens/workers/add_worker_screen.dart';

class DailyAttendanceScreen extends ConsumerStatefulWidget {
  const DailyAttendanceScreen({super.key});

  @override
  ConsumerState<DailyAttendanceScreen> createState() =>
      _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends ConsumerState<DailyAttendanceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final List<String> _shifts = [
    AppConstants.shiftMorning,
    AppConstants.shiftAfternoon,
  ];
  final Map<String, Map<String, String>> _shiftStatuses = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _shifts.length, vsync: this);
    _tabController.addListener(() => setState(() {}));

    // Load existing attendance from Firestore
    Future.microtask(() async {
      final attendanceMap = await ref.read(todayAttendanceProvider.future);
      setState(() {
        _shiftStatuses.clear();
        _shiftStatuses.addAll(attendanceMap);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final workersStreamAsync = ref.watch(allWorkersStreamProvider);
    // final attendanceAsync = ref.watch(todayAttendanceProvider);/

    return currentUserAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (currentUser) {
        final isAdmin = currentUser?.role.name == AppConstants.roleAdmin;

        return DefaultTabController(
          length: _shifts.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Today's Attendance"),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 3.0, color: Colors.blue),
                      insets: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.black54,
                    tabs: _shifts
                        .map(
                          (shift) => Tab(
                            child: Text(
                              shift,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            body: workersStreamAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading workers: $e')),
              data: (workers) {
                if (workers.isEmpty) {
                  return const Center(child: Text("No workers available"));
                }

                return TabBarView(
                  controller: _tabController,
                  children: _shifts.map((shift) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: ListView.builder(
                        key: ValueKey(shift),
                        itemCount: workers.length,
                        itemBuilder: (context, i) {
                          final worker = workers[i];
                          final status =
                              _shiftStatuses[shift]?[worker.id] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: worker.imageUrl.isNotEmpty
                                        ? NetworkImage(worker.imageUrl)
                                        : null,
                                    backgroundColor: Colors.grey[300],
                                    child: worker.imageUrl.isEmpty
                                        ? Text(
                                            worker.name.isNotEmpty
                                                ? worker.name[0].toUpperCase()
                                                : '',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: Colors.black,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          worker.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                await ref
                                                    .read(
                                                      attendanceRepositoryProvider,
                                                    )
                                                    .markAttendance(
                                                      userId: worker.id,
                                                      shift: shift,
                                                      status: AppConstants
                                                          .statusPresent,
                                                      markedBy: currentUser!.id,
                                                    );
                                                setState(() {
                                                  _shiftStatuses[shift] ??= {};
                                                  _shiftStatuses[shift]![worker
                                                      .id] = AppConstants
                                                      .statusPresent;
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.check,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                "Present",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    status ==
                                                        AppConstants
                                                            .statusPresent
                                                    ? Colors.green
                                                    : Colors.grey,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
                                                    ),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                await ref
                                                    .read(
                                                      attendanceRepositoryProvider,
                                                    )
                                                    .markAttendance(
                                                      userId: worker.id,
                                                      shift: shift,
                                                      status: AppConstants
                                                          .statusAbsent,
                                                      markedBy: currentUser!.id,
                                                    );
                                                setState(() {
                                                  _shiftStatuses[shift] ??= {};
                                                  _shiftStatuses[shift]![worker
                                                          .id] =
                                                      AppConstants.statusAbsent;
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                "Absent",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    status ==
                                                        AppConstants
                                                            .statusAbsent
                                                    ? Colors.red
                                                    : Colors.grey,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
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
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            floatingActionButton: isAdmin
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddWorkerScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.person_add),
                  )
                : null,
          ),
        );
      },
    );
  }
}
