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
    return users.add({'name': name, "userId": user?.uid, "date_of_birth": birthdate, 'bio': bio, 'apple_favorite': List.empty(growable: true), 'spotify_favorite': List.empty(growable: true), 'apple_recent': List.empty(growable: true), 'spotify_recent': List.empty(growable: true), 'friend_ids': List.empty(growable: true)})
      .then((value) => print("User added"))
      .catchError((error) => print("Failed to add user"));
  }

  static Future<Map<String, dynamic>> getUserData(String uid) async{
    var uid = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .limit(1)
        .where('userId', isEqualTo: uid)
        .get();
    return snapshot.docs[0].data();
  }
}