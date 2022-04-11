import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_matcher/chat/channel_list_page.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../main.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as s;

import 'channel_page.dart';

UserCredential? user;

class ChatScreen extends StatefulWidget {
  // const ChatScreen({Key? key, required this.client, required this.title, required this.channel}) : super(key: key);
  const ChatScreen({Key? key, required this.client}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final s.StreamChatClient client;
  // final String title;
  // final s.Channel channel;

  @override
  State<ChatScreen> createState() => _ChatScreen();
}

class _ChatScreen extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
          title: Text("CHAT"),
          automaticallyImplyLeading: true,
          //`true` if you want Flutter to automatically add Back Button when needed,
          //or `false` if you want to force your own back button every where
          leading: IconButton(icon:Icon(Icons.arrow_back),
            onPressed:() => Navigator.pop(context, false),
          )
      ),
      body: StreamChat(
        client: widget.client,
        child: ChannelListPage()
      ),
    );
  }
}