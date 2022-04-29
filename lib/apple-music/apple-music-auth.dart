import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import '../models/apple-music-auth-tokens.dart';
import '../models/spotify-auth-tokens.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_matcher/signin/signin-flow.dart';
import 'package:music_matcher/spotify/spotify-auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';

class AppleMusicAuth {

  static String reqToken = '';
  static String getCurrUser = '';

  // Put under authorization bearer header in api requests
  static String devToken = 'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IkoyOTNXWUQ3WVEifQ.eyJpYXQiOjE2NDkyOTIxMDcsImV4cCI6MTY2NDg0NDEwNywiaXNzIjoiM0haVlpHTVNONSJ9.T37bFWgg9gph3zEQF1qgEf7I83wws13-V8ZRQbtzj4nMLylyFH321rbAgk9BAc8E88jiimYn37DJtsaIiN19jg';
  //static String userToken = '';

  static Future<void> getUserData() async {
    //print("Getting AM data");
    var authToken = await AppleMusicAuthTokens.readTokens() as String;
    await getHeavyRotation(authToken);
    await getRecentArtists(authToken);
  }

  static Future<void> storeData() async {
    // Store for current firebase user
    // Store in tracks/artists collections under current user id
    
  }

  static Future<void> getRecentArtists(String token) async {
    String data = await callEndpoint(token, "https://api.music.apple.com/v1/me/recent/played/tracks?limit=10");
    List<String> artists = List.empty(growable: true);
    Map<String, dynamic> decodedData = jsonDecode(data);
    for (var item in decodedData['data']) {
      if (item['attributes']['playParams']['kind'] != 'playlist') {
        if (!artists.contains(item['attributes']['artistName'])) {
          artists.add(item['attributes']['artistName']);
        }
      }
    }

    var user = FirebaseAuth.instance.currentUser;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    QuerySnapshot doc = await users.where('userId', isEqualTo: user?.uid).get();
    DocumentReference ref = doc.docs[0].reference;
    await ref.update({'apple_recent': artists})
      .then((_) => print("Updated"))
      .catchError((error) => print("Error"));
  }

  static Future<void> getHeavyRotation(String token) async {
    var data = await callEndpoint(token, "https://api.music.apple.com/v1/me/history/heavy-rotation");
    List<String> artists = List.empty(growable: true);
    Map<String, dynamic> decodedData = jsonDecode(data);
    for (var item in decodedData['data']) {
      if (item['attributes']['playParams']['kind'] != 'playlist') {
        if (!artists.contains(item['attributes']['artistName'])) {
          artists.add(item['attributes']['artistName']);
        }
      }
    }

    var user = FirebaseAuth.instance.currentUser;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    QuerySnapshot doc = await users.where('userId', isEqualTo: user?.uid).get();
    DocumentReference ref = doc.docs[0].reference;
    await ref.update({'apple_favorite': artists})
      .then((_) => print("Updated"))
      .catchError((error) => print("Error"));
  }

  static Future<String> callEndpoint(String token, String url) async {
    final response = await http.get(Uri.parse(url), headers: { HttpHeaders.authorizationHeader: "Bearer $devToken", "Music-User-Token": token});
    
    if (response.statusCode == 200) {
      //print(json.decode(response.body));
      return response.body;
    } else {
      throw Exception("Failed to get data with status code ${response.statusCode} and reason ${response.reasonPhrase}");
    }
  }

  static void storeUserToken(userToken) {
   AppleMusicAuthTokens token = AppleMusicAuthTokens.fromString(userToken);
   token.saveTokens();
  }

  
}