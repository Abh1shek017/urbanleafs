import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/master_data_model.dart';
import '../services/master_data_service.dart';

final masterDataServiceProvider = Provider<MasterDataService>(
(ref) => MasterDataService(),
name: 'masterDataServiceProvider',
);

// One-shot load from local cache (whatever service returns)
final masterDataProvider = FutureProvider<MasterDataModel>(
(ref) async {
final service = ref.read(masterDataServiceProvider);
return service.getMasterDataModel();
},
name: 'masterDataProvider',
);

// Realtime updates from Firestore, also keeps cache in sync inside the service
final masterDataStreamProvider = StreamProvider<MasterDataModel>(
(ref) {
final service = ref.read(masterDataServiceProvider);
return service.masterDataStream();
},
name: 'masterDataStreamProvider',
);

// Optional: pick stream if available, else fallback to local cache once.
final effectiveMasterDataProvider = Provider<AsyncValue<MasterDataModel>>(
(ref) {
final streamValue = ref.watch(masterDataStreamProvider);
if (streamValue.hasValue || streamValue.isLoading) {
return streamValue;
}
// If stream errors immediately (offline/no permissions), fallback to local cache
final futureValue = ref.watch(masterDataProvider);
return futureValue;
},
name: 'effectiveMasterDataProvider',
);

