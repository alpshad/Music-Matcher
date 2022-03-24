import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../spotify/spotify-auth.dart';

class SpotifyAuthTokens {
  SpotifyAuthTokens(this.accessToken, this.refreshToken);
  String accessToken;
  String refreshToken;

  static String accessTokenKey = 'music-matcher-spotify-access-token';
  static String refreshTokenKey = 'music-matcher-spotify-refresh-token';

  SpotifyAuthTokens.fromJson(Map<String, Object?> json)
    : accessToken = json['access_token'] as String,
      refreshToken = json['refresh_token'] as String;

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken
  };

  Future<void> saveTokens() async {
    try {
      final storage = new FlutterSecureStorage();
      await storage.write(key: accessTokenKey, value: accessToken);
      await storage.write(key: refreshTokenKey, value: refreshToken);
    } catch (e) {
      print(e);
    }
  }

  static Future<SpotifyAuthTokens?> readTokens() async {
    String? accessKey;
    String? refreshKey;
    final storage = new FlutterSecureStorage();
    accessKey = await storage.read(key: accessTokenKey);
    refreshKey = await storage.read(key: refreshTokenKey);
    if (accessKey == null || refreshKey == null) {
      return null;
    }

    return SpotifyAuthTokens(accessKey, refreshKey);
  }

  static Future<void> updateToken() async {
    SpotifyAuthTokens? savedTokens = await readTokens();
    if (savedTokens == null) {
      throw Exception('No saved token');
    }

    var tokens = await SpotifyAuth.getNewTokens(savedTokens);
    await tokens.saveTokens();
  }
}