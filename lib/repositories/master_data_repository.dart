import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/master_data_model.dart';

class MasterDataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MasterDataModel> fetchMasterData() async {
    final doc = await _firestore.collection('masterData').doc('general').get();
    if (doc.exists) {
      return MasterDataModel.fromJson(doc.data()!);
    } else {
      throw Exception('Master data not found');
    }
  }
}
