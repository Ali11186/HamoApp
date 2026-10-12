import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/hive_constants.dart';
import 'data/models/cart_item_model.dart';
import 'firebase_options.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runZonedGuarded(_bootstrap, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show the REAL error on screen instead of Flutter's blank grey box
  // (release builds replace any widget build error with a grey rectangle).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint(
        'FlutterError: ${details.exceptionAsString()}\n${details.stack}');
  };
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFF1A0B0B),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'UI error:\n${details.exceptionAsString()}\n\n${details.stack}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        ),
      );

  // System UI
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase is used for chat only. Firebase Auth remains the app's
  // authentication source; the public publishable key is safe to bundle.
  await Supabase.initialize(
    url: 'https://rynhkubgjxihnqinaazq.supabase.co',
    anonKey: 'sb_publishable_iz1QLm3A7vtLsGlSgU0cgA_VFeezTg3',
  );

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CartItemModelAdapter());
  await Hive.openBox<CartItemModel>(HiveConstants.cartBox);
  await Hive.openBox(HiveConstants.settingsBox);

  runApp(const ProviderScope(child: MohammedStoreApp()));
}

class MohammedStoreApp extends ConsumerWidget {
  const MohammedStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '𝐇𝐚𝐦𝐨',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
