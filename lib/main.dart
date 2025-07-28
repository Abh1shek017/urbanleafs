import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:urbanleafs/routes/app_router.dart';
import 'package:urbanleafs/services/local_storage_service.dart';
import 'package:urbanleafs/themes/app_theme.dart';
import 'package:urbanleafs/themes/dark_theme.dart';
import 'package:urbanleafs/providers/theme_provider.dart';
import 'package:urbanleafs/services/master_data_service.dart';

/// ✅ Global RouteObserver
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MasterDataService().fetchAndUpdateFromFirestore();
  // ✅ Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  final localStorage = LocalStorageService();
  await localStorage.init();

  runApp(ProviderScope(child: MyApp(localStorage: localStorage)));
}


class MyApp extends ConsumerWidget {
  final LocalStorageService localStorage;

  const MyApp({super.key, required this.localStorage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'UrbanLeafs',
      theme: AppThemeManager.getThemeFromEnum(AppTheme.light),
      darkTheme: DarkTheme.theme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
