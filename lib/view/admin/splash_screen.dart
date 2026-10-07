import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bikerental/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    _startSplash();
  }

  // ============================================================
  // START SPLASH SCREEN
  // ============================================================

  Future<void> _startSplash() async {

    // Keep the splash screen visible
    // for 2 seconds.

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) {
      return;
    }

    // Go to Login Page

    Navigator.pushReplacement(
      context,

      MaterialPageRoute(
        builder: (context) =>
            const LoginPage(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFF1B4D3E),

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              // ==================================================
              // APP LOGO
              // ==================================================

              Container(
                width: 110,
                height: 110,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.10,
                      ),

                      blurRadius: 15,

                      offset:
                          const Offset(
                        0,
                        6,
                      ),
                    ),
                  ],
                ),

                child: const Icon(
                  Icons.pedal_bike,

                  size: 60,

                  color:
                      Color(0xFF1B4D3E),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // APP NAME
              // ==================================================

              const Text(
                'Bicycle Rental',

                style: TextStyle(
                  color:
                      Colors.white,

                  fontSize: 28,

                  fontWeight:
                      FontWeight.bold,

                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // SUBTITLE
              // ==================================================

              Text(
                'Easy. Fast. Ride.',

                style: TextStyle(
                  color:
                      Colors.white
                          .withOpacity(
                    0.85,
                  ),

                  fontSize: 14,

                  fontWeight:
                      FontWeight.w400,
                ),
              ),

              const SizedBox(
                height: 50,
              ),

              // ==================================================
              // LOADING INDICATOR
              // ==================================================

              const SizedBox(
                width: 28,
                height: 28,

                child:
                    CircularProgressIndicator(
                  color:
                      Colors.white,

                  strokeWidth: 2.5,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                'Loading...',

                style: TextStyle(
                  color:
                      Colors.white
                          .withOpacity(
                    0.80,
                  ),

                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}