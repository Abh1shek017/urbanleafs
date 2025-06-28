import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

final localStorageServiceProvider =
    Provider<LocalStorageService>((ref) => LocalStorageService());