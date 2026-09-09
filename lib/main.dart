import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'core/services/background_location_service.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable edge-to-edge mode for dynamic navigation bar support
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  
  try {
    await BackgroundLocationService().initialize();
  } catch (_) {}
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Durga Puja Explorer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Forced light theme for beige background
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      ),
    );
  }
}


