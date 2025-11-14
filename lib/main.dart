import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Supabase
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Firebase Init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('\x1B[32mFirebase: Okay\x1B[0m');

  // Supabase Init
  await Supabase.initialize(
    url: 'https://gbmfnuhporizglpzeeji.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdibWZudWhwb3JpemdscHplZWppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NTk1MjAsImV4cCI6MjA3ODUzNTUyMH0.cCI7u2uJLDh6WKQWev3bWIv3lt2OrbBWsS_PQiHHcEM'
  );
  print('\x1B[32mSupabase: Okay\x1B[0m');

  await Future.delayed(const Duration(seconds: 1));
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