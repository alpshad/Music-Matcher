import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  String name;
  DateFormat formatter = DateFormat('mm/dd/yyyy');
  String birthdate = "";
  String bio;

  User(this.name, String birthdate, this.bio) {
    var date = DateFormat('mm/dd/yyyy').parse(birthdate);
    this.birthdate = formatter.format(date);
  }

  Future<void> storeUser() {
    var user = FirebaseAuth.instance.currentUser;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users.add({'name': name, "userId": user?.uid, "date_of_birth": birthdate, 'bio': bio})
      .then((value) => print("User added"))
      .catchError((error) => print("Failed to add user"));
  }

  
}