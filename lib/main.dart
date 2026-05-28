// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter engine is ready before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise notification plugin + timezone data
  await NotificationService.initialize();

  // Force portrait — remove these two lines to allow landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge dark status/nav bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:                   Colors.transparent,
      statusBarIconBrightness:          Brightness.light,
      statusBarBrightness:              Brightness.dark,
      systemNavigationBarColor:         AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskProvider()..init(),
      child:  const LuminaApp(),
    ),
  );
}

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                    'Lumina',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.darkTheme,
      home:                     const HomeScreen(),
    );
  }
}
