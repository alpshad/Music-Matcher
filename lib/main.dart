import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:music_matcher/chat/chat-flow.dart';
import 'package:music_matcher/models/Stream-Api-User.dart';
import 'package:music_matcher/models/apple-music-auth-tokens.dart';
import 'package:music_matcher/signin/signin-flow.dart';
import 'package:music_matcher/spotify/spotify-auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'apple-music/apple-music-auth.dart';
import 'firebase_options.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:age_calculator/age_calculator.dart';

import 'geolocations/nearby-friends-flow.dart';
import 'models/spotify-auth-tokens.dart';

import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as s;
import 'package:music_matcher/models/user.dart' as u;

enum ApplicationLoginState {
  loggedOut,
  emailAddress,
  register,
  password,
  loggedIn,
}

bool userLoggedIn = false;
UserCredential? user;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        userLoggedIn = true;
      } else {
        userLoggedIn = false;
      }
    });

  /// Create a new instance of [StreamChatClient] passing the apikey obtained from your
  /// project dashboard.
  final client = s.StreamChatClient(
    '3zcmfx8umv2e',
    logLevel: s.Level.INFO,);

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final s.StreamChatClient client;
  const MyApp({Key? key, required this.client}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return StreamChat(client: client, child: child);
      },
      title: 'Music Matcher',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color.fromARGB(255, 238, 238, 238)
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => HomeScreen(client: client),
        '/login': (context) => LoginScreen(title: "Music Matcher", client: client),
        '/signup': (context) => SignupScreen(client: client)
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final s.StreamChatClient client;
  const HomeScreen({Key? key, HomeScreen, required this.client}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  static const platform = MethodChannel('apple-music.musicmatcher/auth');
  bool spotifyConnected = false;
  bool appleMusicConnected = false;
  QuerySnapshot? query;

  @override
  void initState() {
    super.initState();
    if(userLoggedIn){
      String uid = FirebaseAuth.instance.currentUser!.uid;
      u.User.getUserData(uid).then((userData) => {
        setupStreamChat(userData)
      });
    }

    SpotifyAuthTokens.readTokens()
    .then((result) => {
      if (result != null) {
        SpotifyAuthTokens.updateToken()
        .then(
          (result) => SpotifyAuth.getUserData().then((result) => {
            print("Finished S data")
          })
        )
      }
    });

    AppleMusicAuthTokens.readTokens()
    .then((result) => {
      if (result != null) {
        AppleMusicAuth.getUserData()
        .then(
            (result) => print("Finished AM data")
        )
      }
    });
  }

  void setupStreamChat(Map<String, dynamic> userData){
    print("userdata is " + userData.toString());
    String birthdate = userData["date_of_birth"]!.replaceAll("/", "-");
    String streamChatUserId = userData["name"]!.replaceAll(" ", "") + birthdate;
    widget.client.connectUser(
      s.User(id: streamChatUserId),
      widget.client.devToken(streamChatUserId).rawValue,
    ).then((result)=> print("finished"));
  }

  Future<void> addFriend(String id) async {
    var user = FirebaseAuth.instance.currentUser;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    QuerySnapshot doc = await users.where('userId', isEqualTo: user?.uid).get();
    DocumentReference ref = doc.docs[0].reference;
    // List<String> friends = List.empty(growable: true);
    // for (String friendId in doc.docs[0].get('friend_ids')) {
    //   friends.add(friendId);
    // }
    List<dynamic> friends = doc.docs[0].get('friend_ids');
    friends.add(id);

    await ref.update({'friend_ids': friends})
      .then((_) => setState(() => {}))
      .catchError((error) => print("Error"));
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getFriends() async {
    var userData = await FirebaseFirestore.instance
                    .collection('users')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .get();
    var userRef = userData.docs[0];
    List<String> friends = List.empty(growable: true);
    var userFriends = await userRef.get("friend_ids");
    for (String friend in userFriends) {
      friends.add(friend);
    }

    if (friends.isNotEmpty) {
      var friendDocs = await FirebaseFirestore.instance
                      .collection('users')
                      .where('userId', whereIn: friends)
                      .get();
      return friendDocs.docs;
    }
    
    return [];
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getSimilarUsers() async {
    var userData = await FirebaseFirestore.instance
                    .collection('users')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .get();
    var userRef = userData.docs[0];
    var userFriends = await userRef.get('friend_ids');
    List<String> friends = List.empty(growable: true);
    for (String friend in userFriends) {
      friends.add(friend);
    }

    friends.add(FirebaseAuth.instance.currentUser!.uid);
    //friends.add('-1');
    //friends.add(await userRef.get('userId'));
    print(friends);

    List<String> recentArtists = List.empty(growable: true);
    var userRecent = await userRef.get('apple_recent');
    for (String stupid in userRecent) {
      recentArtists.add(stupid);
    }
    
    userRecent = await userRef.get('spotify_recent');
    for (String stupid in userRecent) {
      recentArtists.add(stupid);
    }

    List<String> topArtists = List.empty(growable: true);
    var userFavs = await userRef.get('apple_favorite');
    for (String stupid in userFavs) {
      topArtists.add(stupid);
    }

    userFavs = await userRef.get('spotify_favorite');
    for (String stupid in userFavs) {
      topArtists.add(stupid);
    }

    recentArtists = recentArtists.take(10).toList();
    topArtists = topArtists.take(10).toList();

    print(recentArtists);
    var appleRecents = await FirebaseFirestore.instance
              .collection('users')
              .where('userId', isNotEqualTo:  FirebaseAuth.instance.currentUser?.uid)
              .where('apple_recent', arrayContainsAny: recentArtists)
              .limit(10).get();
    var spotRecents = await FirebaseFirestore.instance
              .collection('users')
              .where('userId', isNotEqualTo:  FirebaseAuth.instance.currentUser?.uid)
              .where('spotify_recent', arrayContainsAny: recentArtists)
              .limit(10).get();
    var appleFavs = await FirebaseFirestore.instance
              .collection('users')
              .where('userId', isNotEqualTo:  FirebaseAuth.instance.currentUser?.uid)
              .where('apple_favorite', arrayContainsAny: topArtists)
              .limit(10).get();
    var spotFavs = await FirebaseFirestore.instance
              .collection('users')
              .where('userId', isNotEqualTo:  FirebaseAuth.instance.currentUser?.uid)
              .where('spotify_favorite', arrayContainsAny: topArtists)
              .limit(10)
              .get();
    var docs = appleRecents.docs;
    docs.addAll(spotRecents.docs);
    docs.addAll(appleFavs.docs);
    docs.addAll(spotFavs.docs);
    final ids = Set();
    docs.retainWhere((x) => ids.add(x.get('userId')));
    print(docs.length);
    return docs;
    // Also filter by nearby locations
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music Matcher")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: ElevatedButton (
                child: const Text('Sign Out'),
                onPressed: () async {
                  widget.client.closeConnection();
                  // Sign out
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(context, 
                    MaterialPageRoute(builder: (context) {
                      return LoginScreen(title: "Music Matcher", client: widget.client,);
                    })
                  );
                }
              )
            ),
            Container(
                padding: const EdgeInsets.all(0),
                child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Container(
                        // Spotify not connected
                          padding: const EdgeInsets.all(10),
                          child: const Text("Chat!", textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 24),
                          )
                      ),
                      Container(
                          padding: const EdgeInsets.all(10),
                          child: ElevatedButton(
                            child: Text("Chat"),
                            key: Key("chat"),
                            onPressed: () async {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                              ChannelsBloc(child: StreamChat(client: widget.client, child: ChatScreen(client: widget.client)),
                              )));
                            },
                          )
                      )
                    ]
                )
            ),
            Container(
                 padding: const EdgeInsets.all(0),
                 child: ListView(
                     shrinkWrap: true,
                     children: <Widget>[
                       Container(
                           padding: const EdgeInsets.all(10),
                           child: const Text("Nearby Friends!", textAlign: TextAlign.center,
                             style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 24),
                           )
                       ),
                       Container(
                           padding: const EdgeInsets.all(10),
                           child: ElevatedButton(
                             child: Text("Explore"),
                             onPressed: () async {
                               Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                               ChannelsBloc(child: StreamChat(client: widget.client, child: NearbyFriendsScreen(client: widget.client)),
                               )));
                             },
                           )
                       )
                     ]
                 )
             ),
            FutureBuilder<SpotifyAuthTokens?>(
              // Spotify
              future: SpotifyAuthTokens.readTokens(),
              builder: (BuildContext context, AsyncSnapshot<SpotifyAuthTokens?> snapshot) {
                Widget? child;
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data != null) {
                    // print("Spotify token not null");
                    // FutureBuilder<void>(
                    //   future: getSpotifyDataWhenLoggedIn,
                    //   builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                    //     print("Token updated");

                    //     return const SizedBox(height: 10);
                    //   }
                    // );

                    child = const SizedBox(height: 10);
                  } else {
                    child = Container(
                      padding: const EdgeInsets.all(0),
                      child: ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          Container(
                            // Spotify not connected
                            padding: const EdgeInsets.all(10),
                            child: const Text("Connect to your Spotify account to start matching!", textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 24),
                            )
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: ElevatedButton(
                              child: Text("Connect Account"),
                              onPressed: () async {
                                // Connect to spotify
                                await SpotifyAuth.spotifyAuth();
                                await SpotifyAuth.getUserData();
                                setState(() => { spotifyConnected = true });
                              },
                            )
                          )
                        ]
                      )
                    );
                  }
                } else {
                  child = 
                    const SizedBox(
                      width: 10,
                      height: 60,
                      child: CircularProgressIndicator(),
                    );
                }
                return Container(
                  child: child
                );
              }
              
            ),
            FutureBuilder<String?>(
              // Apple Music
              future: AppleMusicAuthTokens.readTokens(),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                Widget? child;
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data != null) {
                    // FutureBuilder<void>(
                    //   future: AppleMusicAuth.getUserData(),
                    //   builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                    //     return const SizedBox(height: 10);
                    //   }
                    // );

                    child = const SizedBox(height: 10);
                  } else {
                    child = Container(
                      padding: const EdgeInsets.all(0),
                      child: ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          Container(
                            // Spotify not connected
                            padding: const EdgeInsets.all(10),
                            child: const Text("Connect to your Apple Music account to start matching!", textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 24),
                            )
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: ElevatedButton(
                              child: Text("Connect Account"),
                              onPressed: () async {
                                // Connect to Apple Music
                                try {
                                  String userToken = await platform.invokeMethod('appleMusicAuth');
                                  AppleMusicAuth.storeUserToken(userToken);
                                  setState(() => { appleMusicConnected = true });
                                  await AppleMusicAuth.getUserData();
                                  print("album gotten");
                                } on PlatformException {
                                  print("Error connecting to Apple Music");
                                }
                              },
                            )
                          )
                        ]
                      )
                    );
                  }
                } else {
                  child = 
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    );
                }
                return Container(
                  child: child
                );
              }
              
            ),
            FutureBuilder<List<QueryDocumentSnapshot?>>(
              // Other Users
              future: getFriends(),
              builder: (BuildContext context, AsyncSnapshot<List<QueryDocumentSnapshot?>> snapshot) {
                List<Widget> children;
                if (snapshot.connectionState == ConnectionState.done) {
                  children = [];
                  if (snapshot.data != null) {
                    children.add(Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("Your Friends", textAlign: TextAlign.center,
                        style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w500, fontSize: 24),
                      )
                    ));
                    if (snapshot.data!.isEmpty) {
                      children.add(Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white
                        ),
                        child: const Text("No friends yet. Connect with similar users!", textAlign: TextAlign.center,
                          style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w500, fontSize: 20),
                        )
                      ));
                    }

                    for (var doc in snapshot.data!) {
                      children.add(Container(
                        padding: const EdgeInsets.all(0),
                        child: ListView(
                          shrinkWrap: true,
                          primary: false,
                          children: <Widget> [
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white
                              ),
                              padding: const EdgeInsets.all(10),
                              child: ListView(
                                shrinkWrap: true,
                                primary: false,
                                children: <Widget> [
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Text(doc!.get('name'), textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 24),
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Text('${AgeCalculator.age(DateFormat('mm/dd/yyyy').parse(doc.get('date_of_birth'))).years.toString()} years old', textAlign: TextAlign.center,
                                      style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Text(doc.get('bio'), textAlign: TextAlign.center,
                                      style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: ListView(
                                      shrinkWrap: true,
                                      primary: false,
                                      children: <Widget> [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text('Recent Artists: ', textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          )
                                        ),
                                        for(String artist in doc.get('apple_recent'))
                                          Text(artist, textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          ),
                                        for(String artist in doc.get('spotify_recent'))
                                        Text(artist, textAlign: TextAlign.center,
                                          style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                        )
                                      ]
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: ListView(
                                      shrinkWrap: true,
                                      primary: false,
                                      children: <Widget> [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text('Favorite Artists: ', textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          )
                                        ),
                                        for(String artist in doc.get('apple_favorite'))
                                          Text(artist, textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          ),
                                        for(String artist in doc.get('spotify_favorite'))
                                          Text(artist, textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          )
                                      ]
                                    )
                                  ),
                                ]
                              )
                              // SPOTIFY INFO: /me/top/{artists} using time_range long_term and short_term

                            ),
                            const SizedBox(height: 10),

                          ],
                        )
                      ));
                    }
                  }
                } else {
                  children = <Widget> [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    )
                  ];
                }
                return Column(
                      children: children
                    
                );
              }
            ),
            FutureBuilder<List<QueryDocumentSnapshot?>>(
              // Other Users
              future: getSimilarUsers(),
              builder: (BuildContext context, AsyncSnapshot<List<QueryDocumentSnapshot?>> snapshot) {
                List<Widget> children;
                if (snapshot.connectionState == ConnectionState.done) {
                  children = [];
                  if (snapshot.data != null) {
                    children.add(Container(
                      // Spotify not connected
                      padding: const EdgeInsets.all(10),
                      child: const Text("Connect With Similar Users", textAlign: TextAlign.center,
                        style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w500, fontSize: 24),
                      )
                    ));
                    for (var doc in snapshot.data!) {
                      children.add(Container(
                        padding: const EdgeInsets.all(0),
                        child: ListView(
                          shrinkWrap: true,
                          primary: false,
                          children: <Widget> [
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white
                              ),
                              padding: const EdgeInsets.all(10),
                              child: ListView(
                                shrinkWrap: true,
                                primary: false,
                                children: <Widget> [
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Text(doc!.get('name'), textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 24),
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Text('${AgeCalculator.age(DateFormat('mm/dd/yyyy').parse(doc.get('date_of_birth'))).years.toString()} years old', textAlign: TextAlign.center,
                                      style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Text(doc.get('bio'), textAlign: TextAlign.center,
                                      style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: ListView(
                                      shrinkWrap: true,
                                      primary: false,
                                      children: <Widget> [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text('Recent Artists: ', textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          )
                                        ),
                                        for(String artist in doc.get('apple_recent'))
                                          Text(artist, textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          ),
                                        for(String artist in doc.get('spotify_recent'))
                                        Text(artist, textAlign: TextAlign.center,
                                          style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                        )
                                      ]
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 255, 249, 232)
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: ListView(
                                      shrinkWrap: true,
                                      primary: false,
                                      children: <Widget> [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text('Favorite Artists: ', textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          )
                                        ),
                                        for(String artist in doc.get('apple_favorite'))
                                          Text(artist, textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          ),
                                        for(String artist in doc.get('spotify_favorite'))
                                          Text(artist, textAlign: TextAlign.center,
                                            style: TextStyle(color: Color.fromARGB(255, 90, 90, 90), fontWeight: FontWeight.w200, fontSize: 16),
                                          )
                                      ]
                                    )
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 50,
                                    padding: const EdgeInsets.fromLTRB(70, 0, 70, 10),
                                    child: ElevatedButton(
                                      child: const Text('Connect!'),
                                      onPressed: () async {
                                        // Connect
                                        await addFriend(doc.get('userId'));
                                      }
                                    ),
                                  ),
                                ]
                              )
                              // SPOTIFY INFO: /me/top/{artists} using time_range long_term and short_term

                            ),
                            const SizedBox(height: 10),

                          ],
                        )
                      ));
                    }
                  }
                } else {
                  children = <Widget> [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    )
                  ];
                }
                return Column(
                      children: children
                    
                );
              }
            ),
          ]
        )
      )
    );
  }
}

