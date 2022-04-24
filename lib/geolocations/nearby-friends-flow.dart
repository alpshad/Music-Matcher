import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as s;
import 'package:music_matcher/chat/chat-flow.dart';
import 'package:music_matcher/models/Stream-Api-User.dart';

/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
///
///
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   // await Geolocator.requestPermission();
//   runApp(MaterialApp(
//     title: 'Geo Flutter Fire example',
//     home: NearbyFriendsScreen(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

class NearbyFriendsScreen extends StatefulWidget {
  const NearbyFriendsScreen({Key? key, required this.client}) : super(key: key);
  final s.StreamChatClient client;
  @override
  _NearbyFriendsScreenState createState() => _NearbyFriendsScreenState();
}

class _NearbyFriendsScreenState extends State<NearbyFriendsScreen> {
  LocationData? _currentPosition;
  GoogleMapController? _mapController;
  TextEditingController? _latitudeController, _longitudeController;
  Location location = Location();

  GoogleMapController? _controller;
  LatLng _initialcameraposition = const LatLng(32.23193637129737, -110.94996986837795);

  // firestore init
  final radius = BehaviorSubject<double>.seeded(0.0);
  final _firestore = FirebaseFirestore.instance;
  final markers = <MarkerId, Marker>{};
  final circles = <CircleId, Circle>{};

  Geoflutterfire geo = Geoflutterfire();

  late GeoFirePoint center;
  late Stream<List<DocumentSnapshot>> stream;

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    getLoc();

    center = geo.point(latitude: 32.23193637129737, longitude: -110.94996986837795);

    stream = radius.switchMap((rad) {
      final collectionReference = _firestore.collection('geolocations');

      return geo.collection(collectionRef: collectionReference).within(
          center: center, radius: 1.6 * rad, field: 'position', strictMode: true);
    });

    // _firestore.collection('geolocations').get().then((snapshot) {
    //   for (DocumentSnapshot ds in snapshot.docs){
    //     ds.reference.delete();
    //   }});
    //
    _firestore
        .collection('geolocations')
        .add({'name': 'James', 'position': geo.point(latitude: 32.28480489100139, longitude: -110.94488968029498)},
    ).then((_) {
      ;
    });

  }

  void _onMapCreated(GoogleMapController _cntlr)
  {
    _controller = _controller;
    location.onLocationChanged.listen((l) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(l.latitude!, l.longitude!),zoom: 15),
        ),
      );
    });
    location.onLocationChanged.listen((l) {
      center = geo.point(latitude: l.latitude!, longitude: l.longitude!);
    });
    stream.listen((List<DocumentSnapshot> documentList) {
      _updateMarkers(documentList);
    });
  }

  @override
  void dispose() {
    _latitudeController?.dispose();
    _longitudeController?.dispose();
    radius.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Friends'),
          automaticallyImplyLeading: true,
            leading: IconButton(icon:Icon(Icons.arrow_back),
              onPressed:() => Navigator.pop(context, false),
            ),
        ),
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: mediaQuery.size.width - 30,
                    height: mediaQuery.size.height * (2 / 3),
                    child:GoogleMap(
                        initialCameraPosition: CameraPosition(target: _initialcameraposition,
                        zoom: 15),
                        mapType: MapType.normal,
                        onMapCreated: _onMapCreated,
                        mapToolbarEnabled: false,
                        myLocationEnabled: true,
                        circles: Set<Circle>.of(circles.values),
                        markers: Set<Marker>.of(markers.values),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Slider(
                  min: 0,
                  max: 30,
                  divisions: 6,
                  value: _value,
                  label: _label,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.blue.withOpacity(0.2),
                  onChanged: (double value) => changed(value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _addMarker(double lat, double lng, String name) async {
    BitmapDescriptor markerbitmap = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      r"C:\Users\Raymond\StudioProjects\Music-Matcher\assets\images\assets\images\user.png",
    );

    final _markerid = MarkerId(lat.toString() + lng.toString());
    final _marker = Marker(
      markerId: _markerid,
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      // icon: markerbitmap,
      // infoWindow: InfoWindow(title: 'Name and Location', snippet: '$name,$lat,$lng'),
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => s.ChannelsBloc(child: s.StreamChat(client: widget.client, child: NearbyFriendsProfile(client: widget.client)))),
        );
      }
    );
    final _circleid = CircleId(lat.toString() + lng.toString());
    final _circle = Circle(
      circleId: _circleid,
      center: LatLng(lat, lng),
      fillColor: Colors.blueAccent.withOpacity(0.2),
      strokeColor: Colors.blueAccent.withOpacity(0.0),
      radius: 2000,
    );
    setState(() {
      markers[_markerid] = _marker;
      circles[_circleid] = _circle;
    });
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    documentList.forEach((DocumentSnapshot document) {
      final data = document.data() as Map<String, dynamic>;
      final GeoPoint point = data['position']['geopoint'];
      _addMarker(point.latitude, point.longitude, data['name']);
    });
  }

  double _value = 0.0;
  String _label = '';

  changed(value) {
    setState(() {
      _value = value;
      _label = '${_value.toInt().toString()} miles';
      markers.clear();
      circles.clear();
    });
    radius.add(value);
  }

  getLoc() async{
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _currentPosition = await location.getLocation();
    _initialcameraposition = LatLng(_currentPosition!.latitude!,_currentPosition!.longitude!);
    location.onLocationChanged.listen((LocationData currentLocation) {
      print("${currentLocation.longitude} : ${currentLocation.longitude}");
      setState(() {
        _currentPosition = currentLocation;
        _initialcameraposition = LatLng(_currentPosition!.latitude!,_currentPosition!.longitude!);
      });
    });
  }
}


class NearbyFriendsProfile extends StatelessWidget {
  final s.StreamChatClient client;
  const NearbyFriendsProfile({Key? key, HomeScreen, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Column(
        children: [
          Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Image(
                  height: MediaQuery.of(context).size.height / 3,
                  fit: BoxFit.cover,
                  image: const NetworkImage(
                      'https://www.worldatlas.com/r/w768/upload/07/b4/c5/blues.jpg'),
                ),
                Positioned(
                    bottom: -50.0,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.black,
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=880&q=80'),
                      ),
                    ))
              ]),
          SizedBox(
            height: 45,
          ),
          ListTile(
            title: Center(child: Text('John')),
            subtitle: Center(child: Text('Rhythm and blues')),
          ),
          ListTile(
            title: Text('About me'),
            subtitle: Text(
                'I like Rhythm and blues'),
          ),
          SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 20,
          ),
          ListTile(
            title: Text('Social'),
            subtitle: Row(
              children: [
                Expanded(
                  child: IconButton(
                      icon: FaIcon(FontAwesomeIcons.facebook),
                      onPressed: () {}),
                ),
                Expanded(
                  child: IconButton(
                      icon: FaIcon(FontAwesomeIcons.instagram),
                      onPressed: () {}),
                ),
              ],
            ),
          ),
          ElevatedButton(onPressed: () async {
            // String username = s.StreamChat.of(context).currentUser!.name;
            // String id = s.StreamChat.of(context).currentUser!.id;
            // String url = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=880&q=80";
            // StreamApi.initUser(client, username: username, urlImage: url, id: id, token: client.devToken(id).rawValue);
            // final otherUser = "John";
            // final channel = await StreamApi.createChannel(client, type: "messaging", name: otherUser, id: id, image: url, idMembers: [id, otherUser]);
            // StreamApi.watchChannel(client, type: type, id: id);

            Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
            // s.ChannelsBloc(child: s.StreamChat(client: client, child: ChatScreen(client: client, channel: channel,title: otherUser)),
            s.ChannelsBloc(child: s.StreamChat(client: client, child: ChatScreen(client: client)),
            )));
          },
          child: const Text(r"Let's Chat!"),
          )
        ],
      ),
    );
  }
}