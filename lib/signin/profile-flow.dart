import 'package:flutter/material.dart';

import '../main.dart';
import '../models/user.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as s;


class ProfileScreen extends StatefulWidget {
  final s.StreamChatClient client;
  const ProfileScreen({Key? key, ProfileScreen, required this.client}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController dateController = TextEditingController(text: "mm/dd/yyyy");
  final _formKey = GlobalKey<FormState>();
  String creationError = "";

  Future<void> createProfile(String name, String birthdate, String bio) {
    String date_of_birth = birthdate.replaceAll("/", "-");
    s.User streamchatuser =  s.User(id: name + date_of_birth);
    widget.client.updateUser(streamchatuser);
    User user = User(name, birthdate, bio);
    return user.storeUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music Matcher")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text(
                  'Create Profile',
                  style: TextStyle(fontSize: 20),
                )),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget> [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() => creationError = "");

                        return 'Name Required';
                      }
                      return null;
                    },
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Name',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() => creationError = "");

                        return 'Date of Birth Required';
                      }

                      if (!new RegExp("[0-9]{2}/[0-9]{2}/[0-9]{4}").hasMatch(value)) {
                        setState(() => creationError = "");

                        return 'Incorrect Format: mm/dd/yyyy';
                      }
                      return null;
                    },
                    controller: dateController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Date of Birth',
                    ),
                  )
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextFormField(
                    controller: bioController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Bio',
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: ElevatedButton(
                    child: const Text('Create!'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Log in
                        await createProfile(nameController.text, dateController.text, bioController.text);
                          // Signed in
                          print("Profile Created");
                          Navigator.pushReplacement(context, 
                            MaterialPageRoute(builder: (context) {
                              return HomeScreen(client: widget.client,);
                            })
                          );
                        }
                      }
                    ),
                  ),
                  Text(creationError, 
                    style: TextStyle(
                      color: Colors.red
                    ),
                  ),
                ]
              ),
            ),
          ]
        )
      )
    );
  }
}