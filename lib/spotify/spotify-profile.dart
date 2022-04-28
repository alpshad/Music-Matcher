import 'package:flutter/material.dart';

import '../main.dart';
import '../spotify/spotify-user.dart';

class spotifyProfileScreen extends StatefulWidget {
  SpotifyUser? spotifyProfile;
  spotifyProfileScreen({Key? key,this.spotifyProfile}) : super(key: key);

  @override
  State<spotifyProfileScreen> createState() => _spotifyProfileScreen();
}




class _spotifyProfileScreen extends State<spotifyProfileScreen> {
  //SpotifyUser spotifyProfile = SpotifyUser();

  final _formKey = GlobalKey<FormState>();
  String creationError = "";

  // Future<void> spotifyCreateProfile(String name, String email, String country) {
  //   SpotifyUser user = SpotifyUser(name:name, email:email, country:country);
  //   return user.storeUser();
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music Matcher")),
      body: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
              children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(0),
                      child: ListView(
                          shrinkWrap: true,
                          children: <Widget>[
                            Container(
                              // Spotify not connected
                                child:  Text("Account name: ${widget.spotifyProfile?.name}", textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 24),
                                )
                            ),
                            Container(
                              // Spotify not connected
                                child:  Text("email address: ${widget.spotifyProfile?.email}", textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 24),
                                )
                            ),
                            Container(
                              // Spotify not connected
                                child:  Text("Country: ${widget.spotifyProfile?.country}", textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 24),
                                )
                            ),
                          ]
                      )
                  ),


              ]
          )
      )
    );
  }
}