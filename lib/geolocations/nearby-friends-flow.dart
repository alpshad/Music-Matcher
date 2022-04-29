import 'dart:typed_data';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:music_matcher/models/geolocation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as s;
import 'package:music_matcher/chat/chat-flow.dart';
import 'package:music_matcher/models/user.dart';
import 'package:music_matcher/models/Stream-Api-User.dart';
import 'package:music_matcher/models/geolocation.dart';

import '../chat/channel_page.dart';

/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
///
///
class _FriendListItem extends StatelessWidget {
  final DocumentSnapshot document;
  late Map<String, dynamic> data;
  late s.StreamChatClient client;

  _FriendListItem(this.document, this.client){
    data = document.data() as Map<String, dynamic>;
    client = client;
  }


  @override
  Widget build(BuildContext context) {
    return ListTile(
      /*
        leading: CircleAvatar(
            radius: 30.0,
            backgroundImage: NetworkImage('https://img.rawpixel.com/s3fs-private/rawpixel_images/website_content/v1059-041c-kv7v7wnb.jpg?w=800&dpr=1&fit=default&crop=default&q=65&vib=3&con=3&usm=15&bg=F4F4F3&ixlib=js-2.2.1&s=9281c9dc720656a8e68d0f75f2a22e40'),
            backgroundColor: Colors.transparent
        ),
       */
        title: Text(data['name']),
        // subtitle: Text(data['genres']),
        onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => s.ChannelsBloc(child: s.StreamChat(client: client, child: NearbyFriendsProfile(client: client, data: data,)))),
          );
        }
    );
  }

}

class FriendsList extends StatelessWidget {
  final List<DocumentSnapshot> documentList;
  final s.StreamChatClient client;

  FriendsList(this.documentList, this.client);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return ConstrainedBox(
        constraints: BoxConstraints(
        minHeight: 50,
        maxHeight: 200,
        ),
     child:ListView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: _buildFriendsList()
    ),
    );
  }

  List<_FriendListItem> _buildFriendsList() {
    return documentList.map((document) => _FriendListItem(document, client))
        .toList();
  }

}

class NearbyFriendsScreen extends StatefulWidget {
  const NearbyFriendsScreen({Key? key, required this.client}) : super(key: key);
  final s.StreamChatClient client;
  @override
  _NearbyFriendsScreenState createState() => _NearbyFriendsScreenState(client);
}

class _NearbyFriendsScreenState extends State<NearbyFriendsScreen> {
  LocationData? _currentPosition;
  TextEditingController? _latitudeController, _longitudeController;
  Location location = Location();
  List<DocumentSnapshot> _document = [];
  final s.StreamChatClient client;

  _NearbyFriendsScreenState(this.client);

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
      final collectionReference = _firestore.collection('geolocations2');

      return geo.collection(collectionRef: collectionReference).within(
          center: center, radius: 1.6 * rad, field: 'position', strictMode: true);
    });
    // _firestore.collection('geolocations').get().then((snapshot) {
    //   for (DocumentSnapshot ds in snapshot.docs){
    //     ds.reference.delete();
    //   }});
    //
    /*
    _firestore
        .collection('geolocations')
        .add({'name': 'James', 'position': geo.point(latitude: 32.28480489100139, longitude: -110.94488968029498)},
    ).then((_) {
      ;
    });
     */
  }

  void _onMapCreated(GoogleMapController _cntlr)
  {
    _controller = _cntlr;
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
      _document = documentList;
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
                    height: mediaQuery.size.height * (3/4),
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
              // FriendsList(_document, client),
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

  _addMarker(double lat, double lng, String name, Map<String, dynamic> data) async {
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
          MaterialPageRoute(builder: (context) => s.ChannelsBloc(child: s.StreamChat(client: widget.client, child: NearbyFriendsProfile(client: widget.client, data: data,)))),
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
    _document = documentList;
    documentList.forEach((DocumentSnapshot document) {
      final data = document.data() as Map<String, dynamic>;
      final GeoPoint point = data['position']['geopoint'];
      User.getUserData(data['userId']).then((value) => {_addMarker(point.latitude, point.longitude, value['name'], value)});
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
    GeoPoint point = GeoPoint(_currentPosition!.latitude!, _currentPosition!.longitude!);
    GeoLocation g = GeoLocation(point);
    g.addOrUpdateGeoLocation();
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
  final Map<String, dynamic> data;
  NearbyFriendsProfile({Key? key, HomeScreen, required this.client, required this.data}) : super(key: key);

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
                  image: NetworkImage('https://img.rawpixel.com/s3fs-private/rawpixel_images/website_content/v1059-041c-kv7v7wnb.jpg?w=800&dpr=1&fit=default&crop=default&q=65&vib=3&con=3&usm=15&bg=F4F4F3&ixlib=js-2.2.1&s=9281c9dc720656a8e68d0f75f2a22e40'),
                ),
                Positioned(
                    bottom: -50.0,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.black,
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: NetworkImage("https://www.google.com/url?sa=i&url=https%3A%2F%2Fsumaleeboxinggym.com%2Ftestimonial%2Ffamily-friendly-fighting-fitness%2Fgeneric-profile-1600x1600%2F&psig=AOvVaw07kBFE14bRKpukt_iQYcC2&ust=1651303379872000&source=images&cd=vfe&ved=0CAwQjRxqFwoTCKjx6c3euPcCFQAAAAAdAAAAABAJ")
                      ),
                    ))
              ]),

          SizedBox(
            height: 45,
          ),
          ListTile(
            title: Center(child: Text(data['name'].toString())),
            // subtitle: Center(child: Text(data['genres'])),
          ),
          ListTile(
            title: Text('About me'),
            subtitle: Text(data['bio']),
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
            String username = s.StreamChat.of(context).currentUser!.name;
            String id = s.StreamChat.of(context).currentUser!.id;
            String url = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=880&q=80";
            StreamApi.initUser(client, username: username, urlImage: url, id: id, token: client.devToken(id).rawValue);
            String birthdate = data["date_of_birth"]!.replaceAll("/", "-");
            String streamChatUserId = data["name"]! + birthdate;
            final channel = await StreamApi.createChannel(client, type: "messaging", name: streamChatUserId, id: id, image: url, idMembers: [id, "Amir"]);
            StreamApi.watchChannel(client, type: channel.type, id: channel!.id!);


            Navigator.of(context).push(MaterialPageRoute(builder: (_) =>

            // s.ChannelsBloc(child: s.StreamChat(client: client, child: ChatScreen(client: client, channel: channel,title: otherUser)),
            s.ChannelsBloc(child: s.StreamChannel(child: ChannelPage(), channel: channel)),
            ));
          },
          child: const Text(r"Let's Chat!"),
          )
        ],
      ),
    );
  }
}