import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class StreamApi {
  static Future initUser(
      StreamChatClient client, {
        required String username,
        required String urlImage,
        required String id,
        required String token,
      }) async {
    final user = User(
      id: id,
      extraData: {
        'name': username,
        'image': urlImage,
      },
    );

    await client.connectUser(user, token);
  }

  static Future<Channel> createChannel(
      StreamChatClient client, {
        required String type,
        required String name,
        required String id,
        required String image,
        List<String> idMembers = const [],
      }) async {
    final channel = client.channel(type, id: id, extraData: {
      'name': name,
      'image': image,
      'members': idMembers,
    });

    await channel.create();

    channel.watch();
    return channel;
  }

  static Future<Channel> watchChannel(
      StreamChatClient client, {
        required String type,
        required String id,
      }) async {
    final channel = client.channel(type, id: id);

    channel.watch();
    return channel;
  }
}