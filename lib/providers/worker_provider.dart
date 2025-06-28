import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_model.dart';
import '../repositories/worker_repository.dart';

/// Provider for WorkerRepository
final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return WorkerRepository();
});

/// StreamProvider to watch all workers in real-time
final allWorkersStreamProvider = StreamProvider<List<WorkerModel>>((ref) {
  final workerRepo = ref.watch(workerRepositoryProvider);
  return workerRepo.getAllWorkersStream();
});

/// FutureProvider to check if a worker with the given mobile exists
final workerExistsProvider = FutureProvider.family<bool, String>((ref, mobile) {
  final workerRepo = ref.watch(workerRepositoryProvider);
  return workerRepo.checkIfWorkerExists(mobile);
});
