import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

enum ApplicationLoginState {
  loggedOut,
  emailAddress,
  register,
  password,
  loggedIn,
}

bool userLoggedIn = false;
UserCredential? user;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        userLoggedIn = true;
      } else {
        userLoggedIn = false;
      }
    });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Matcher',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(title: 'Music Matcher Login'),
    );
  }
}

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
                  'Sign in',
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
                  onPressed: () {
                    //forgot password screen
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
                          print(nameController.text);
                          print(passwordController.text);
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
                      child: const Text('Sign in'),
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
                                return HomeScreen();
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
            )
          ]
        )
      )
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, HomeScreen}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music Matcher")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: ElevatedButton (
                child: const Text('Sign Out'),
                onPressed: () async {
                  // Sign out
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(context, 
                    MaterialPageRoute(builder: (context) {
                      return LoginScreen(title: "Music Matcher");
                    })
                  );
                }
              )
            )
          ]
        )
      )
    );
  }
}