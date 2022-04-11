import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class User {
  String name = "";
  DateFormat formatter = DateFormat('mm/dd/yyyy');
  String birthdate = "";
  String bio = "";

  User(String name, String birthdate, String bio) {
    name = name;
    var date = DateFormat('mm/dd/yyyy').parse(birthdate);
    birthdate = formatter.format(date);
    bio = bio;
  }

  Future<void> storeUser() {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users.add({'name': name, "date_of_birth": birthdate, 'bio': bio})
      .then((value) => print("User added"))
      .catchError((error) => print("Failed to add user"));
  }
}