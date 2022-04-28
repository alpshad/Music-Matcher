import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

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

String spotifyClientID = "ed9e36fd550e4bdb854a0e810e79107f";
String spotifyClientSecret = "fd746f0b1f764a5983aa5274c3840cd8";

class SpotifyAuth {
  // static Client client = HttpClientWithInterceptor.build(interceptors: [
  //   SpotifyInterceptor(),
  // ], retryPolicy: ExpiredTokenRetryPolicy());

  static List<String> scopes = [
    'user-read-private',
    'user-read-email',
    'user-library-read',
    'user-top-read',
    'user-read-recently-played',
    'user-follow-read',
    'playlist-read-collaborative',
    'app-remote-control'
  ];

  static String reqAuth(String clientId, String redirectUri, String state) {
    //print(scopes.join('%20'));
    return 'https://accounts.spotify.com/authorize?response_type=code&client_id=$clientId&scope=${scopes.join('%20')}&redirect_uri=$redirectUri&state=$state';
  }

  static String reqToken = 'https://accounts.spotify.com/api/token';
  static String getCurrUser = 'https://api.spotify.com/v1/me';

  static Future<void> getUserData() async {
    //print("Getting S data");
    await getHeavyRotation();
    await getRecentArtists();
  }

  static Future<bool> getCurrentUser() async {
    var authToken = await SpotifyAuthTokens.readTokens();
    final response = await http.get(
      Uri.parse(SpotifyAuth.getCurrUser), headers: { HttpHeaders.authorizationHeader: "Bearer ${authToken?.accessToken}"});

    print(response.headers);

    if (response.statusCode == 200) {
      //return User.fromJson(json.decode(response.body));
      print(json.decode(response.body));
      return true;
    } else {
      throw Exception(
          'Failed to get user with status code ${response.statusCode}');
    }
  }

  static Future<bool?> spotifyAuth() async {
    const redirectUri = "musicmatcher:/";
    const state = "spotifyState";

    try {
      print (spotifyClientID);
      String result = await FlutterWebAuth.authenticate(url: SpotifyAuth.reqAuth(spotifyClientID, redirectUri, state), callbackUrlScheme: "musicmatcher");
      String? returnedState = Uri.parse(result).queryParameters['state'];
      if (state != returnedState) {
        throw HttpException('Unable to access Spotify');
      }

      String? code = Uri.parse(result).queryParameters['code'];
      var tokens = await getSpotifyAuthTokens(code, redirectUri);
      await tokens.saveTokens();

      return await SpotifyAuth.getCurrentUser();
    
    } on Exception catch (e) {
      print(e);
      return null;
    }
  }

  static Future<SpotifyAuthTokens> getSpotifyAuthTokens(String? code, String redirectUri) async {
    var base64Cred = utf8.fuse(base64).encode('$spotifyClientID:$spotifyClientSecret');
    var response = await http.post(Uri.parse(SpotifyAuth.reqToken), body: {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
    }, headers: { HttpHeaders.authorizationHeader: 'Basic $base64Cred' });
    print(response.reasonPhrase);

    if (response.statusCode == 200) {
      print(json.decode(response.body));
      return SpotifyAuthTokens.fromJson(json.decode(response.body));
    } else {
      throw Exception('Unable to connect to spotify with status code ${response.statusCode}');
    }
  }

  static Future<SpotifyAuthTokens> getNewTokens(SpotifyAuthTokens originalTokens) async {
    var base64Cred = utf8.fuse(base64).encode('$spotifyClientID:$spotifyClientSecret');
    var response = await http.post(Uri.parse(reqToken),
    body: {
      'grant_type': 'refresh_token',
      'refresh_token': originalTokens.refreshToken
    }, headers: {HttpHeaders.authorizationHeader: 'Basic $base64Cred'});

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      if (responseBody['refresh_token'] == null) {
        responseBody['refresh_token'] = originalTokens.refreshToken;
      }

      return SpotifyAuthTokens.fromJson(responseBody);
    } else {
      throw Exception('Failed to refresh token with status code ${response.statusCode}');
    }
  }

  static Future<void> getRecentArtists() async {
    var authToken = await SpotifyAuthTokens.readTokens();
    String data = await callEndpoint(authToken, "https://api.spotify.com/v1/me/player/recently-played?limit=10");
    List<String> artists = List.empty(growable: true);
    Map<String, dynamic> decodedData = jsonDecode(data);
    for (var item in decodedData['items']) {
      //print("item");
      //print(item);
      for (var artist in item['track']['artists']) {
        if (!artists.contains(artist['name'])) {
          artists.add(artist['name']);
        }
      }
    }

    //print(artists);

    var user = FirebaseAuth.instance.currentUser;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    QuerySnapshot doc = await users.where('userId', isEqualTo: user?.uid).get();
    DocumentReference ref = doc.docs[0].reference;
    await ref.update({'spotify_recent': artists})
      .then((_) => print("Updated"))
      .catchError((error) => print("Error"));
  }

  static Future<void> getHeavyRotation() async {
    var authToken = await SpotifyAuthTokens.readTokens();
    var data = await callEndpoint(authToken, "https://api.spotify.com/v1/me/top/artists?limit=10");
    List<String> artists = List.empty(growable: true);
    Map<String, dynamic> decodedData = jsonDecode(data);
    //print("data");
    //print(data);
    for (var item in decodedData['items']) {
      for (var artist in item['track']['artists']) {
        if (!artists.contains(artist['name'])) {
          artists.add(artist['name']);
        }
      }
    }

    var user = FirebaseAuth.instance.currentUser;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    QuerySnapshot doc = await users.where('userId', isEqualTo: user?.uid).get();
    DocumentReference ref = doc.docs[0].reference;
    await ref.update({'spotify_favorite': artists})
      .then((_) => print("Updated"))
      .catchError((error) => print("Error"));
  }

  static Future<String> callEndpoint(SpotifyAuthTokens? authToken, String url) async {
    final response = await http.get(Uri.parse(url), headers: { HttpHeaders.authorizationHeader: "Bearer ${authToken?.accessToken}"});
    
    if (response.statusCode == 200) {
      //print(json.decode(response.body));
      return response.body;
    } else {
      throw Exception("Failed to get data with status code ${response.statusCode} and reason ${response.reasonPhrase}");
    }
  }
}