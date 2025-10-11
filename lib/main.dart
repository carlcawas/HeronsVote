import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash screen visible while we load resources
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Simulate initialization (e.g., loading assets, Firebase, etc.)
  await Future.delayed(const Duration(seconds: 1));

  // Remove the native splash *after* initialization is done
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HeronsVote',
      theme: ThemeData(
        fontFamily: 'Geist',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF273E58)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
