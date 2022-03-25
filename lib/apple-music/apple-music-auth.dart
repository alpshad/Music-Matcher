import 'package:http/http.dart' as http;
import 'package:music_matcher/models/spotify-user.dart';
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

class AppleMusicAuth {

  static String reqToken = 'https://accounts.spotify.com/api/token';
  static String getCurrUser = 'https://api.spotify.com/v1/me';


  static Future<SpotifyUser> getCurrentUser() async {
    var authToken = await SpotifyAuthTokens.readTokens();
    final response = await http.get(
      Uri.parse(SpotifyAuth.getCurrUser), headers: { HttpHeaders.authorizationHeader: "Bearer ${authToken?.accessToken}"});

    print(response.headers);

    if (response.statusCode == 200) {
      //return User.fromJson(json.decode(response.body));
      print(json.decode(response.body));
      return SpotifyUser();
    } else {
      throw Exception(
          'Failed to get user with status code ${response.statusCode}');
    }
  }

  static Future<SpotifyUser?> appleMusicAuth() async {
    const redirectUri = "musicmatcher:/";
    const state = "spotifyState";

    try {

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
}