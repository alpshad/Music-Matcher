import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeoLocation{
  GeoPoint point;
  late Map<String, GeoPoint> position;

  GeoLocation(this.point){
    GeoHasher geoHasher = GeoHasher();
    String hash = geoHasher.encode(this.point.longitude, this.point.latitude);
    this.position = {hash: this.point};
  }

  void storeGeoLocation() {
    var user = FirebaseAuth.instance.currentUser;
    CollectionReference geolocations = FirebaseFirestore.instance.collection('geolocations2');
    geolocations.add({"userId": user!.uid, "position": this.point})
        .then((value) => print("geolocation added"))
        .catchError((error) => print("Failed to add geolocation"));
  }

  Future<void> addOrUpdateGeoLocation() async{
    var uid = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance
        .collection('geolocations2')
        .limit(1)
        .where('userId', isEqualTo: uid)
        .get();
    if(snapshot.docs.isNotEmpty){
      String docId = snapshot.docs[0].id;
      FirebaseFirestore.instance.collection('geolocations2').doc(docId).update({'position': this.position});
    }
    else{
      storeGeoLocation();
    }
  }

}
