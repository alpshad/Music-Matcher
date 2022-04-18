import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../spotify/spotify-auth.dart';

class AppleMusicAuthTokens {
  AppleMusicAuthTokens(this.userToken);
  String userToken;

  static String accessTokenKey = 'music-matcher-apple-music-access-token';

  AppleMusicAuthTokens.fromString(String token)
    : userToken = token;

  Future<void> saveTokens() async {
    try {
      print(userToken);
      final storage = new FlutterSecureStorage();
      await storage.write(key: accessTokenKey, value: userToken);
    } catch (e) {
      print(e);
    }
  }

  static Future<String?> readTokens() async {
    String? accessKey;
    final storage = new FlutterSecureStorage();
    accessKey = await storage.read(key: accessTokenKey);
    if (accessKey == null) {
      return null;
    }

    return accessKey;
  }

  // static Future<void> updateToken() async {
  //   SpotifyAuthTokens? savedTokens = await readTokens();
  //   if (savedTokens == null) {
  //     throw Exception('No saved token');
  //   }

  //   var tokens = await SpotifyAuth.getNewTokens(savedTokens);
  //   await tokens.saveTokens();
  // }
}