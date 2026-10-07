
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bikerental/service/auth_service.dart';
import 'package:bikerental/service/user_service.dart';
import 'package:bikerental/model/user_model.dart';

import 'package:bikerental/view/admin/dashboard_page.dart';
import 'package:bikerental/view/customer/home_page.dart';
import 'package:bikerental/view/staff/staff_dashboard.dart';

import 'register_page.dart';

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

  bool isLoading = false;
  bool obscurePassword = true;
  bool rememberMe = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // EMAIL AND PASSWORD LOGIN
  // =========================================================

  Future<void> login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(
        'Please enter your email and password.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      User? user = await authService.login(
        email,
        password,
      );

      if (user == null) {
        showMessage('Login failed.');
        return;
      }

      // Get user information from Firestore
      UserModel? userData =
          await userService.getUser(user.uid);

      if (userData == null) {
        await authService.logout();

        showMessage(
          'User account information was not found.',
        );
        return;
      }

      // Check if account is active
      if (userData.active == false) {
        await authService.logout();

        showMessage(
          'Your account is currently inactive.',
        );
        return;
      }

      // Get role
      final String role =
          (userData.role ?? '').toLowerCase();

      if (!mounted) {
        return;
      }

      // =====================================================
      // ADMIN
      // =====================================================

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AdminDashboard(),
          ),
        );
      }

      // =====================================================
      // STAFF
      // =====================================================

      else if (role == 'staff') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const StaffDashboard(),
          ),
        );
      }

      // =====================================================
      // CUSTOMER
      // =====================================================

      else if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CustomerHomePage(),
          ),
        );
      }

      // =====================================================
      // INVALID ROLE
      // =====================================================

      else {
        await authService.logout();

        showMessage(
          'Invalid user role.',
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }

      showMessage(message);
    } catch (e) {
      showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // GOOGLE LOGIN
  // =========================================================

  Future<void> loginWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user =
          await authService.loginWithGoogle();

      if (user == null) {
        return;
      }

      // Check if Google user already exists
      UserModel? userData =
          await userService.getUser(user.uid);

      // Create new Google users as customers
      if (userData == null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'phoneNumber': '',
          'role': 'customer',
          'active': true,
          'createdAt':
              FieldValue.serverTimestamp(),
        });

        userData =
            await userService.getUser(user.uid);
      }

      if (userData == null) {
        await authService.logout();

        showMessage(
          'Unable to load your account information.',
        );
        return;
      }

      // Check if account is active
      if (userData.active == false) {
        await authService.logout();

        showMessage(
          'Your account is currently inactive.',
        );
        return;
      }

      final String role =
          (userData.role ?? '').toLowerCase();

      if (!mounted) {
        return;
      }

      // =====================================================
      // ADMIN
      // =====================================================

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AdminDashboard(),
          ),
        );
      }

      // =====================================================
      // STAFF
      // =====================================================

      else if (role == 'staff') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const StaffDashboard(),
          ),
        );
      }

      // =====================================================
      // CUSTOMER
      // =====================================================

      else if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CustomerHomePage(),
          ),
        );
      }

      // =====================================================
      // INVALID ROLE
      // =====================================================

      else {
        await authService.logout();

        showMessage(
          'Invalid user role.',
        );
      }
    } catch (e) {
      showMessage(
        'Google login failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // LOGIN PAGE UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen =
        Color(0xFF1E4D40);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FB),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 20,
            ),

            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 420,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [

                  // =================================================
                  // GO PEDAL LOGO
                  // =================================================

                  const Icon(
                    Icons.pedal_bike,
                    size: 70,
                    color: primaryGreen,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'GoPedal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  const Text(
                    'Bicycle Rental Application',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Colors.black54,
                    ),
                  ),

                  const SizedBox(
                    height: 35,
                  ),

                  // =================================================
                  // EMAIL
                  // =================================================

                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  TextField(
                    controller:
                        emailController,

                    keyboardType:
                        TextInputType.emailAddress,

                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter your email',

                      prefixIcon:
                          const Icon(
                        Icons.email_outlined,
                      ),

                      filled: true,

                      fillColor:
                          Colors.white,

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),

                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              Color(0xFFE0E0E0),
                        ),
                      ),

                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              primaryGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // PASSWORD
                  // =================================================

                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  TextField(
                    controller:
                        passwordController,

                    obscureText:
                        obscurePassword,

                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter your password',

                      prefixIcon:
                          const Icon(
                        Icons.lock_outline,
                      ),

                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),

                        onPressed: () {
                          setState(() {
                            obscurePassword =
                                !obscurePassword;
                          });
                        },
                      ),

                      filled: true,

                      fillColor:
                          Colors.white,

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),

                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              Color(0xFFE0E0E0),
                        ),
                      ),

                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              primaryGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // =================================================
                  // REMEMBER ME / FORGOT PASSWORD
                  // =================================================

                  Row(
                    children: [

                      Checkbox(
                        value:
                            rememberMe,

                        activeColor:
                            primaryGreen,

                        onChanged:
                            (value) {
                          setState(() {
                            rememberMe =
                                value ??
                                    false;
                          });
                        },
                      ),

                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),

                      const Spacer(),

                      TextButton(
                        onPressed: () {
                          showMessage(
                            'Forgot password feature is not available yet.',
                          );
                        },

                        child:
                            const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color:
                                primaryGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // =================================================
                  // LOGIN BUTTON
                  // =================================================

                  SizedBox(
                    height: 52,

                    child:
                        ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : login,

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryGreen,

                        foregroundColor:
                            Colors.white,

                        elevation: 0,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              'Login',
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // =================================================
                  // OR DIVIDER
                  // =================================================

                  Row(
                    children: [

                      Expanded(
                        child:
                            Divider(
                          color:
                              Colors.grey.shade300,
                        ),
                      ),

                      Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 15,
                        ),

                        child:
                            const Text(
                          'OR',
                          style:
                              TextStyle(
                            color:
                                Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      Expanded(
                        child:
                            Divider(
                          color:
                              Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // =================================================
                  // GOOGLE LOGIN
                  // =================================================

                  SizedBox(
                    height: 52,

                    child:
                        OutlinedButton(
                      onPressed:
                          isLoading
                              ? null
                              : loginWithGoogle,

                      style:
                          OutlinedButton.styleFrom(
                        backgroundColor:
                            Colors.white,

                        side:
                            const BorderSide(
                          color:
                              Color(0xFFE0E0E0),
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      child:
                          Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [

                          const Icon(
                            Icons
                                .account_circle_outlined,
                            color:
                                Colors.black87,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          const Text(
                            'Continue with Google',
                            style:
                                TextStyle(
                              color:
                                  Colors.black87,
                              fontSize:
                                  14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // =================================================
                  // SIGN UP
                  // =================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [

                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.black54,
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const RegisterPage(),
                            ),
                          );
                        },

                        child:
                            const Text(
                          'Sign Up',
                          style:
                              TextStyle(
                            color:
                                primaryGreen,
                            fontWeight:
                                FontWeight.bold,
                            fontSize:
                                13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
