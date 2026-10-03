import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/model/user_model.dart';

class UserService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

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
}