import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bikerental/service/auth_service.dart';
import 'package:bikerental/service/user_service.dart';

import 'package:bikerental/view/admin/staff/customer/home_page.dart';
import 'package:bikerental/view/admin/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService authService = AuthService();

  final UserService userService = UserService();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool loading = false;

  Future<void> login() async {
    // Check if email and password are empty
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter email and password.',
          ),
        ),
      );
      return;
    }

    // Show loading
    setState(() {
      loading = true;
    });

    try {
      // Login using Firebase Authentication
      User? user = await authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      // If login failed
      if (user == null) {
        throw Exception(
          'Incorrect email or password.',
        );
      }

      // Get user information from Firestore
      final userData = await userService.getUser(
        user.uid,
      );

      // Check if user document exists
      if (userData == null) {
        throw Exception(
          'User information not found.',
        );
      }

      // Check if account is active
      if (!userData.active) {
        throw Exception(
          'Your account is disabled.',
        );
      }

      if (!mounted) return;

      // Check user role
      if (userData.role == 'admin') {
        // Go to Admin Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AdminDashboard(),
          ),
        );
      } else if (userData.role == 'customer') {
        // Go to Customer Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const DashboardPage(),
          ),
        );
      } else {
        // Unknown role
        throw Exception(
          'Invalid user role.',
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';

      if (e.code == 'user-not-found') {
        message = 'No account found.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      // Always stop loading
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bicycle Rental',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // Email
            TextField(
              controller: emailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : login,
                child: Text(
                  loading
                      ? 'Logging in...'
                      : 'Login',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}