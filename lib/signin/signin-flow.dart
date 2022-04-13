import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_matcher/signin/profile-flow.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';

import '../main.dart';

UserCredential? user;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, required this.title}) : super(key: key);
  

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<LoginScreen> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String loginError = "";

  Future<bool> login(String username, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: username,
        password: password
      );

      user = userCredential;
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        loginError = 'No user found for that email.';
        return true;
      } else if (e.code == 'wrong-password') {
        loginError = 'Wrong password provided for that user.';
        return true;
      }
      loginError = "Error";
      return true;
    }
  }

  @override 
  Future<void> resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text(
                  'Music Matcher',
                  style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 30),
                )),
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text(
                  'Log in',
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
                        setState(() => loginError = "");

                        return 'Email Required';
                      }
                      return null;
                    },
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() => loginError = "");
                        return 'Password Required';
                      }
                      return null;
                    },
                    obscureText: true,
                    controller: passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    //forgot password screen
                    await resetPassword(FirebaseAuth.instance.currentUser?.email ?? "");
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                        return ForgotPasswordScreen();
                      })
                    );
                  },
                  child: const Text(
                    'Forgot Password',
                  ),
                ),
                Container(
                    height: 50,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: ElevatedButton(
                      child: const Text('Login'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Log in
                          bool error = await login(nameController.text, passwordController.text);
                          if (!error)
                          {
                            // Signed in
                            print("Signed in");
                            Navigator.pushReplacement(context, 
                              MaterialPageRoute(builder: (context) {
                                return HomeScreen();
                              })
                            );
                          }
                          else {
                            setState(() => loginError = loginError);
                          }
                        }
                      },
                    )
                  ),
                  Text(loginError, 
                    style: TextStyle(
                      color: Colors.red
                    ),
                  ),
                ]
              ),
            ),
            Row(
              children: <Widget>[
                const Text('No account?'),
                TextButton(
                  child: const Text(
                    'Sign up',
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return SignupScreen();
                      }),
                    );
                    //signup screen
                  },
                )
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  
  @override
  State<SignupScreen> createState() => _SignupScreen();
}

class _SignupScreen extends State<SignupScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String signupError = "";

  Future<bool> signup(String username, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: username,
        password: password
      );

      user = userCredential;
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        signupError = 'The password provided is too weak.';
        return true;
      } else if (e.code == 'email-already-in-use') {
        signupError = 'The account already exists for that email.';
        return true;
      }
      signupError = "Error";
      return true;
    } catch (e) {
      signupError = "Error";
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music Matcher")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(children: <Widget>[
          Align(
              alignment: Alignment.topLeft,
              child: ElevatedButton (
                child: const Text('Back'),
                onPressed: () async {
                  // Sign out
                  Navigator.pushReplacement(context, 
                    MaterialPageRoute(builder: (context) {
                      return LoginScreen(title: "Music Matcher");
                    })
                  );
                }
              )
            ),
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'Music Matcher',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 30),
              )),
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'Sign up',
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
                      setState(() => signupError = "");
                      return 'Email Required';
                    }
                    return null;
                  },
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      setState(() => signupError = "");
                      return 'Password Required';
                    }
                    return null;
                  },
                  obscureText: true,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),
              Container(
                    height: 50,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: ElevatedButton(
                      child: const Text('Sign up'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Log in
                          print(nameController.text);
                          print(passwordController.text);                        
                          bool error = await signup(nameController.text, passwordController.text);
                          if (!error)
                          {
                            // Signed in
                            Navigator.pushReplacement(context, 
                              MaterialPageRoute(builder: (context) {
                                return ProfileScreen();
                              })
                            );
                          }
                          else {
                            setState(() => signupError = signupError);
                          }
                        }
                      },
                    )
                  ),
                  Text(signupError,
                    style: TextStyle(
                      color: Colors.red
                    ),
                  ),
                ]
              )
            ),
            Row(
              children: <Widget>[
                const Text('Have an account?'),
                TextButton(
                  child: const Text(
                    'Log in',
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return const LoginScreen(title: "Music Matcher");
                      }),
                    );
                    //signup screen
                  },
                )
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ]
        )
      )
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);
  
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreen();
}

class _ForgotPasswordScreen extends State<ForgotPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music Matcher")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(children: <Widget>[
          Align(
              alignment: Alignment.topLeft,
              child: ElevatedButton (
                child: const Text('Back'),
                onPressed: () async {
                  // Sign out
                  Navigator.pushReplacement(context, 
                    MaterialPageRoute(builder: (context) {
                      return LoginScreen(title: "Music Matcher");
                    })
                  );
                }
              )
            ),
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'Email Sent!',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 30),
              )),
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Text(
                'A password reset email was sent to ${FirebaseAuth.instance.currentUser?.email}',
                style: TextStyle(fontSize: 20),
              )),
        ])
      )
    );
  }
}