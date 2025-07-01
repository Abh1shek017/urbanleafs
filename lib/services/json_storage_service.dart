import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class JsonStorageService {
  static const String fileName = 'master_data.json';

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    if (!(await file.exists())) {
      await _initializeFile(file);
    }
    return file;
  }

  Future<void> _initializeFile(File file) async {
    final initialData = {
      "customers": [],
      "inventoryTypes": [],
      "units": [],
      "itemTypes": [],
      "orderItems": [],
      "expenseTypes": [],
    };
    await file.writeAsString(jsonEncode(initialData));
  }

  Future<Map<String, dynamic>> getMasterData() async {
    final file = await _getLocalFile();
    try {
      final contents = await file.readAsString();
      final data = jsonDecode(contents);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (e) {
      print('Error reading JSON file: $e');
    }
    // fallback in case of error or empty file
    return {
      "customers": [],
      "inventoryTypes": [],
      "units": [],
      "itemTypes": [],
      "orderItems": [],
      "expenseTypes": [],
    };
  }

  Future<List<dynamic>> getField(String field) async {
    final data = await getMasterData();
    return data[field] ?? [];
  }

  Future<void> updateMasterDataField(String field, List<dynamic> data) async {
    final allData = await getMasterData();
    allData[field] = data;
    final file = await _getLocalFile();
    await file.writeAsString(jsonEncode(allData));
  }

  Future<void> saveMasterData(Map<String, dynamic> data) async {
    final file = await _getLocalFile();
    await file.writeAsString(jsonEncode(data));
  }
}
