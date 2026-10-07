import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:bikerental/view/admin/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'GoPedal',

      theme: ThemeData(
        primarySwatch: Colors.blue,

        scaffoldBackgroundColor:
            const Color(0xFFF7F9FB),

        fontFamily: 'Arial',
      ),

      home: const SplashScreen(),
    );
  }
}