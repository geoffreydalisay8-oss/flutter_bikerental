import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
        ),
      ),

      body: Column(
        children: [

          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),

            child: TextField(
              controller: searchController,

              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Role filter
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),

            child: DropdownButtonFormField<String>(
              value: selectedRole,

              decoration: const InputDecoration(
                labelText: 'Filter by Role',
                border: OutlineInputBorder(),
              ),

              items: const [
                DropdownMenuItem(
                  value: 'All',
                  child: Text('All Users'),
                ),
                DropdownMenuItem(
                  value: 'customer',
                  child: Text('Customer'),
                ),
                DropdownMenuItem(
                  value: 'staff',
                  child: Text('Staff'),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: Text('Admin'),
                ),
              ],

              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // User list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),

              builder: (context, snapshot) {

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

                // Filter users
                final users = allUsers.where((user) {

                  final data =
                      user.data()
                          as Map<String, dynamic>;

                  final name =
                      (data['name'] ?? '')
                          .toString()
                          .toLowerCase();

                  final email =
                      (data['email'] ?? '')
                          .toString()
                          .toLowerCase();

                  final role =
                      (data['role'] ?? '')
                          .toString();

                  final search =
                      searchController.text
                          .toLowerCase();

                  final matchesSearch =
                      name.contains(search) ||
                      email.contains(search);

                  final matchesRole =
                      selectedRole == 'All' ||
                      role == selectedRole;

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
                  itemCount: users.length,

                  itemBuilder:
                      (context, index) {

                    final user =
                        users[index];

                    final data =
                        user.data()
                            as Map<String, dynamic>;

                    final name =
                        data['name'] ?? '';

                    final email =
                        data['email'] ?? '';

                    final phone =
                        data['phone'] ?? '';

            

                    final role =
                        data['role'] ??
                            'customer';

                    final active =
                        data['active'] ??
                            true;

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      child: ListTile(

                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.person,
                          ),
                        ),

                        title: Text(
                          name,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          '$email\n'
                          '$phone\n'
                          'Role: $role\n'
                          'Status: '
                          '${active ? 'Active' : 'Disabled'}',
                        ),

                        isThreeLine: true,

                        trailing:
                            const Icon(
                          Icons.arrow_forward_ios,
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

  // ==========================================
  // USER DETAILS
  // ==========================================

  void showUserDetails(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {

    final name =
        data['name'] ?? '';

    final email =
        data['email'] ?? '';

    final phone =
        data['phone'] ?? '';

    final address =
        data['address'] ?? '';

    final role =
        data['role'] ?? 'customer';

    final active =
        data['active'] ?? true;

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(
          title: const Text(
            'User Details',
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'Name: $name',
                ),

                const SizedBox(height: 8),

                Text(
                  'Email: $email',
                ),

                const SizedBox(height: 8),

                Text(
                  'Phone: $phone',
                ),

                const SizedBox(height: 8),

                Text(
                  'Address: $address',
                ),

                const SizedBox(height: 8),

                Text(
                  'Role: $role',
                ),

                const SizedBox(height: 8),

                Text(
                  'Status: '
                  '${active ? 'Active' : 'Disabled'}',
                ),
              ],
            ),
          ),

          actions: [

            // Change role
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                changeRole(
                  context,
                  userId,
                  role,
                );
              },

              child: const Text(
                'Change Role',
              ),
            ),

            // Enable / Disable
            TextButton(
              onPressed: () async {

                await FirebaseFirestore
                    .instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'active': !active,
                });

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
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
                Navigator.pop(context);
              },

              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // CHANGE ROLE
  // ==========================================

  void changeRole(
    BuildContext context,
    String userId,
    String currentRole,
  ) {

    String newRole = currentRole;

    showDialog(
      context: context,

      builder: (context) {

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {

            return AlertDialog(
              title: const Text(
                'Change User Role',
              ),

              content:
                  DropdownButtonFormField<String>(
                value: newRole,

                items: const [
                  DropdownMenuItem(
                    value: 'customer',
                    child: Text('Customer'),
                  ),
                  DropdownMenuItem(
                    value: 'staff',
                    child: Text('Staff'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
                ],

                onChanged: (value) {
                  setDialogState(() {
                    newRole = value!;
                  });
                },
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
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
                      'role': newRole,
                    });

                    if (!context.mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'User role updated.',
                        ),
                      ),
                    );
                  },

                  child: const Text(
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
