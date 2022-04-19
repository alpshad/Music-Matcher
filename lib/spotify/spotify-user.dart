
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


// class SpotifyUser {
//   String userID;
//
//   SpotifyUser({this.userID: " amoo"});
//
// }
//



class SpotifyUser {
  String name;
  String email;
  String country;

  SpotifyUser(this.name,this.email, this.country);

  Future<void> storeUser() {
    CollectionReference users = FirebaseFirestore.instance.collection('spotifyUsers');
    return users.add({'name': name, 'email':email, 'country':country})
        .then((value) => print("Spotify user profile created"))
        .catchError((error) => print("Failed to create spotify user profiel"));
  }
}