import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:music_matcher/signin/signin-flow.dart';
import 'package:music_matcher/spotify/spotify-auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

import 'models/apple-music-user.dart';
import 'models/spotify-auth-tokens.dart';
import 'models/spotify-user.dart';

enum ApplicationLoginState {
  loggedOut,
  emailAddress,
  register,
  password,
  loggedIn,
}

bool userLoggedIn = false;
UserCredential? user;
SpotifyUser? spotifyUser;
AppleMusicUser? appleMusicUser;

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(title: "Music Matcher"),
        '/signup': (context) => const SignupScreen()
      },
    );
  }
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, HomeScreen}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  //static const platform = MethodChannel('apple-music.musicmatcher/auth');

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
                  // Sign out
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(context, 
                    MaterialPageRoute(builder: (context) {
                      return LoginScreen(title: "Music Matcher");
                    })
                  );
                }
              )
            ),
            if (spotifyUser != null)
              // Spotify connected
              const Text("hello world")
            else
              Container(
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
                          spotifyUser = await SpotifyAuth.spotifyAuth();
                          setState(() => { spotifyUser != null });
                        },
                      )
                    )
                  ]
                )
              ),
            if (appleMusicUser != null)
              // Apple Music connected
              const Text("hello world")
            else
              Container(
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
                            //appleMusicUser = await platform.invokeMethod('appleMusicAuth');
                            setState(() => { appleMusicUser != null });
                          } on PlatformException catch (e) {
                            print("Error connecting to Apple Music");
                          }
                        },
                      )
                    )
                  ]
                )
              )
          ]
        )
      )
    );
  }
}

