import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/model/user_model.dart';

class UserService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await users.doc(userId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  // Get user by ID
  // This is used by CustomerProfilePage
  Future<UserModel?> getUserById(String userId) async {
    DocumentSnapshot doc = await users.doc(userId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  // Create user
  Future<void> createUser({
    required String uid,
    required String fullName,
    required String email,
    required String role,
    required bool active,
  }) async {
    await users.doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}