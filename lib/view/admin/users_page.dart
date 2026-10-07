
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:bikerental/firebase_options.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() =>
      _ManageUsersState();
}

class _ManageUsersState
    extends State<ManageUsers> {

  final TextEditingController searchController =
      TextEditingController();

  String selectedRole = 'All';

  // =========================================================
  // ADD STAFF
  // =========================================================

  void showAddStaffDialog() {

    final TextEditingController nameController =
        TextEditingController();

    final TextEditingController emailController =
        TextEditingController();

    final TextEditingController passwordController =
        TextEditingController();

    final TextEditingController phoneController =
        TextEditingController();

    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {

            return AlertDialog(
              title: const Text(
                'Add Staff',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    TextField(
                      controller:
                          nameController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Full Name',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Email',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          passwordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Password',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          phoneController,
                      keyboardType:
                          TextInputType.phone,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Phone Number (Optional)',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [

                TextButton(
                  onPressed:
                      isCreating
                          ? null
                          : () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child:
                      const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed:
                      isCreating
                          ? null
                          : () async {

                    final String name =
                        nameController
                            .text
                            .trim();

                    final String email =
                        emailController
                            .text
                            .trim();

                    final String password =
                        passwordController
                            .text
                            .trim();

                    final String phone =
                        phoneController
                            .text
                            .trim();

                    if (name.isEmpty ||
                        email.isEmpty ||
                        password.isEmpty) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill in the required fields.',
                          ),
                        ),
                      );

                      return;
                    }

                    if (password.length < 6) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password must be at least 6 characters.',
                          ),
                        ),
                      );

                      return;
                    }

                    setDialogState(() {
                      isCreating = true;
                    });

                    try {

                      // =================================================
                      // CREATE SECONDARY FIREBASE APP
                      // This prevents the Admin from being logged out.
                      // =================================================

                      final String appName =
                          'staffCreation_${DateTime.now().millisecondsSinceEpoch}';

                      final FirebaseApp secondaryApp =
                          await Firebase.initializeApp(
                        name: appName,
                        options:
                            DefaultFirebaseOptions
                                .currentPlatform,
                      );

                      final FirebaseAuth secondaryAuth =
                          FirebaseAuth.instanceFor(
                        app: secondaryApp,
                      );

                      User? staffUser;

                      try {

                        final UserCredential
                            credential =
                            await secondaryAuth
                                .createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        staffUser =
                            credential.user;

                        if (staffUser == null) {
                          throw Exception(
                            'Unable to create staff account.',
                          );
                        }

                        // =================================================
                        // CREATE STAFF FIRESTORE DOCUMENT
                        // =================================================

                        await FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(staffUser!.uid)
                            .set({
                          'uid':
                              staffUser!.uid,
                          'name':
                              name,
                          'fullName':
                              name,
                          'email':
                              email,
                          'phoneNumber':
                              phone,
                          'phone':
                              phone,
                          'role':
                              'staff',
                          'active':
                              true,
                          'createdAt':
                              FieldValue
                                  .serverTimestamp(),
                        });

                      } catch (e) {

                        // If Firestore creation fails,
                        // try to remove the Auth account.
                        if (staffUser != null) {
                          try {
                            await staffUser!.delete();
                          } catch (_) {}
                        }

                        rethrow;

                      } finally {

                        await secondaryAuth.signOut();

                        await secondaryApp.delete();
                      }

                      if (!mounted) {
                        return;
                      }

                      Navigator.pop(
                        context,
                      );

                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Staff account created successfully.',
                          ),
                        ),
                      );

                    } on FirebaseAuthException catch (e) {

                      String message =
                          'Unable to create staff account.';

                      if (e.code ==
                          'email-already-in-use') {
                        message =
                            'This email is already registered.';
                      } else if (e.code ==
                          'invalid-email') {
                        message =
                            'Invalid email address.';
                      } else if (e.code ==
                          'weak-password') {
                        message =
                            'Password is too weak.';
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          SnackBar(
                            content:
                                Text(message),
                          ),
                        );
                      }

                    } catch (e) {

                      if (mounted) {
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error creating staff: $e',
                            ),
                          ),
                        );
                      }

                    } finally {

                      if (context.mounted) {
                        setDialogState(() {
                          isCreating = false;
                        });
                      }
                    }
                  },

                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add Staff',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'User Management',
        ),

        actions: [

          IconButton(
            tooltip: 'Add Staff',
            icon: const Icon(
              Icons.person_add,
            ),

            onPressed:
                showAddStaffDialog,
          ),
        ],
      ),

      body: Column(
        children: [

          // =====================================================
          // SEARCH BAR
          // =====================================================

          Padding(
            padding:
                const EdgeInsets.all(12),

            child: TextField(
              controller:
                  searchController,

              decoration:
                  InputDecoration(
                hintText:
                    'Search users...',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // =====================================================
          // ROLE FILTER
          // =====================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),

            child:
                DropdownButtonFormField<String>(
              value:
                  selectedRole,

              decoration:
                  const InputDecoration(
                labelText:
                    'Filter by Role',
                border:
                    OutlineInputBorder(),
              ),

              items: const [

                DropdownMenuItem(
                  value: 'All',
                  child:
                      Text('All Users'),
                ),

                DropdownMenuItem(
                  value: 'customer',
                  child:
                      Text('Customer'),
                ),

                DropdownMenuItem(
                  value: 'staff',
                  child:
                      Text('Staff'),
                ),

                DropdownMenuItem(
                  value: 'admin',
                  child:
                      Text('Admin'),
                ),
              ],

              onChanged: (value) {
                setState(() {
                  selectedRole =
                      value!;
                });
              },
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // =====================================================
          // USER LIST
          // =====================================================

          Expanded(
            child:
                StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore
                      .instance
                      .collection('users')
                      .snapshots(),

              builder:
                  (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found.',
                    ),
                  );
                }

                final allUsers =
                    snapshot.data!.docs;

                // =================================================
                // FILTER USERS
                // =================================================

                final users =
                    allUsers.where((user) {

                  final data =
                      user.data()
                          as Map<String, dynamic>;

                  final name =
                      (
                        data['name'] ??
                        data['fullName'] ??
                        ''
                      )
                          .toString()
                          .toLowerCase();

                  final email =
                      (
                        data['email'] ??
                        ''
                      )
                          .toString()
                          .toLowerCase();

                  final role =
                      (
                        data['role'] ??
                        ''
                      )
                          .toString()
                          .toLowerCase();

                  final search =
                      searchController
                          .text
                          .toLowerCase();

                  final matchesSearch =
                      name.contains(
                            search,
                          ) ||
                      email.contains(
                            search,
                          );

                  final matchesRole =
                      selectedRole ==
                              'All' ||
                          role ==
                              selectedRole;

                  return matchesSearch &&
                      matchesRole;

                }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching users found.',
                    ),
                  );
                }

                return ListView.builder(

                  itemCount:
                      users.length,

                  itemBuilder:
                      (context, index) {

                    final user =
                        users[index];

                    final data =
                        user.data()
                            as Map<String, dynamic>;

                    final name =
                        data['name'] ??
                        data['fullName'] ??
                        '';

                    final email =
                        data['email'] ??
                        '';

                    final phone =
                        data['phone'] ??
                        data['phoneNumber'] ??
                        '';

                    final role =
                        data['role'] ??
                        'customer';

                    final active =
                        data['active'] ??
                        true;

                    return Card(

                      margin:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      child: ListTile(

                        leading:
                            CircleAvatar(
                          child: Icon(
                            role
                                    .toString()
                                    .toLowerCase() ==
                                'staff'
                                ? Icons
                                    .support_agent
                                : Icons.person,
                          ),
                        ),

                        title: Text(
                          name.toString(),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        subtitle:
                            Text(
                          '$email\n'
                          '$phone\n'
                          'Role: $role\n'
                          'Status: '
                          '${active ? 'Active' : 'Disabled'}',
                        ),

                        isThreeLine:
                            true,

                        trailing:
                            const Icon(
                          Icons
                              .arrow_forward_ios,
                          size: 18,
                        ),

                        onTap: () {
                          showUserDetails(
                            context,
                            user.id,
                            data,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // USER DETAILS
  // =========================================================

  void showUserDetails(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {

    final name =
        data['name'] ??
        data['fullName'] ??
        '';

    final email =
        data['email'] ??
        '';

    final phone =
        data['phone'] ??
        data['phoneNumber'] ??
        '';

    final address =
        data['address'] ??
        '';

    final role =
        data['role'] ??
        'customer';

    final active =
        data['active'] ??
        true;

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(

          title:
              const Text(
            'User Details',
          ),

          content:
              SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'Name: $name',
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Email: $email',
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Phone: $phone',
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Address: $address',
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Role: $role',
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Status: '
                  '${active ? 'Active' : 'Disabled'}',
                ),
              ],
            ),
          ),

          actions: [

            // =================================================
            // CHANGE ROLE
            // =================================================

            TextButton(
              onPressed: () {

                Navigator.pop(
                  context,
                );

                changeRole(
                  context,
                  userId,
                  role.toString()
                      .toLowerCase(),
                );
              },

              child:
                  const Text(
                'Change Role',
              ),
            ),

            // =================================================
            // ENABLE / DISABLE
            // =================================================

            TextButton(
              onPressed: () async {

                await FirebaseFirestore
                    .instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'active': !active,
                });

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(
                  context,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      active
                          ? 'Account disabled.'
                          : 'Account enabled.',
                    ),
                  ),
                );
              },

              child: Text(
                active
                    ? 'Disable'
                    : 'Enable',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },

              child:
                  const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // CHANGE ROLE
  // =========================================================

  void changeRole(
    BuildContext context,
    String userId,
    String currentRole,
  ) {

    String newRole =
        currentRole;

    // Make sure old documents
    // with an unexpected role don't
    // break the dropdown.
    if (newRole != 'customer' &&
        newRole != 'staff' &&
        newRole != 'admin') {
      newRole = 'customer';
    }

    showDialog(
      context: context,

      builder: (context) {

        return StatefulBuilder(

          builder: (
            context,
            setDialogState,
          ) {

            return AlertDialog(

              title:
                  const Text(
                'Change User Role',
              ),

              content:
                  DropdownButtonFormField<String>(
                value: newRole,

                items: const [

                  DropdownMenuItem(
                    value: 'customer',
                    child:
                        Text('Customer'),
                  ),

                  DropdownMenuItem(
                    value: 'staff',
                    child:
                        Text('Staff'),
                  ),

                  DropdownMenuItem(
                    value: 'admin',
                    child:
                        Text('Admin'),
                  ),
                ],

                onChanged: (value) {

                  if (value == null) {
                    return;
                  }

                  setDialogState(() {
                    newRole =
                        value;
                  });
                },
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child:
                      const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {

                    await FirebaseFirestore
                        .instance
                        .collection('users')
                        .doc(userId)
                        .update({
                      'role':
                          newRole,
                    });

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(
                      context,
                    );

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'User role updated.',
                        ),
                      ),
                    );
                  },

                  child:
                      const Text(
                    'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }
}