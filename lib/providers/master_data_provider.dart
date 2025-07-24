import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/master_data_model.dart';
import '../repositories/master_data_repository.dart';
import '../services/master_data_service.dart';
final masterDataRepositoryProvider = Provider<MasterDataRepository>(
  (ref) => MasterDataRepository(),
);

final masterDataServiceProvider = Provider<MasterDataService>((ref) {
  return MasterDataService();
});

final masterDataProvider = FutureProvider<MasterDataModel>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.getMasterDataModel();
});
