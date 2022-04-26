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

import 'models/spotify-auth-tokens.dart';

import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as s;

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
    var userId = "";
    String? email = "";
    email = FirebaseAuth.instance.currentUser?.email;

    if(email == "alpshadow@gmail.com" || email == "thecatnamedwinter@gmail.com"){
      userId = "Amy";
    }
    else if(email == "mariov7757@gmail.com"){
      userId = "Mario";
    }
    else if(email == "ziruihuang@email.arizona.edu"){
      userId = "Ray";
    }
    else if(email == "amir.hya@gmail.com" || email == "amirtest1@gmail.com"){
      userId = "Amir";
    }

    widget.client.connectUser(
      s.User(id: userId),
      widget.client.devToken(userId).rawValue,
    ).then((result)=> print("finished"));
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
                            onPressed: () async {
                              /*
                              String username = StreamChat.of(context).currentUser!.name;
                              String id = StreamChat.of(context).currentUser!.id;
                              String url = "http://cdn.onlinewebfonts.com/svg/img_56553.png";
                              StreamApi.initUser(widget.client, username: username, urlImage: url, id: id, token: widget.client.devToken(id).rawValue);
                              final otherUser = "Ray";
                              final channel = await StreamApi.createChannel(widget.client, type: "messaging", name: otherUser, id: id, image: url, idMembers: [id, otherUser]);
                              // StreamApi.watchChannel(client, type: type, id: id)

                               */
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                                  // ChannelsBloc(child: StreamChat(client: widget.client, child: ChatScreen(client: widget.client, channel: channel,title: otherUser)),
                              ChannelsBloc(child: StreamChat(client: widget.client, child: ChatScreen(client: widget.client)),
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
            FutureBuilder<QuerySnapshot?>(
              // Other Users
              future: FirebaseFirestore.instance
                        .collection('users')
                        .limit(10)
                        .get(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot?> snapshot) {
                List<Widget> children;
                if (snapshot.connectionState == ConnectionState.done) {
                  children = [];
                  if (snapshot.data != null) {
                    for (var doc in snapshot.data!.docs) {
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
                                    child: Text(doc.get('name'), textAlign: TextAlign.center,
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
                                        for(String artist in doc.get('recent'))
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
                                        for(String artist in doc.get('favorite'))
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

