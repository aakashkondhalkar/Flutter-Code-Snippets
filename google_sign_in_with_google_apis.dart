/// Flutter Google Sign In Example
///
/// This widget demonstrates how to use Flutter Google Sign In Api to login user using gmail account.
/// Also how to retrive extra user info such as user birthday and gender using google apis
///
/// Author: Aakash Kondhalkar
/// Date: July 2, 2023
///


/*
Configure you project in firebase.

Configure your project in google cloud deveploper console (https://console.cloud.google.com/apis/dashboard).
Enable `People APIs` from APIs & Services section 
And also, check if app has approved for `OAuth consent screen`, 
If not, then get your app approved by completing the OAuth consent screen form in the developer console.

***** Need below pubs in pubspec.yaml in order run this code ******

firebase_core: ^2.14.0
google_sign_in: ^6.1.4
firebase_auth: ^4.6.3
googleapis: ^11.2.0
googleapis_auth: ^1.4.1
extension_google_sign_in_as_googleapis_auth: ^2.0.10

*/


import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/people/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // this options generated by default if you configure firebase using flutterfire CLI tool
  );
  runApp(const MyApp());
}

/// The scopes required by this application.
const List<String> scopes = <String>[
  PeopleServiceApi.userEmailsReadScope,
  PeopleServiceApi.userGenderReadScope,
  PeopleServiceApi.userBirthdayReadScope,
];

GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: 'your_id.apps.googleusercontent.com',
  scopes: scopes,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false; // has granted permissions?
  String _contactText = '';
  String? name;
  String? gender;
  String? birthday;

  @override
  void initState() {
    super.initState();

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleGetContact();
      }
    });
    _googleSignIn.signInSilently();
  }

  // Calls the People API REST endpoint for the signed-in user to retrieve information.
  Future<void> _handleGetContact() async {
    setState(() {
      _contactText = 'Loading contact info...';
    });

    // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
    final auth.AuthClient? client = await _googleSignIn.authenticatedClient();
    //
    // assert(client != null, 'Authenticated client missing!');
    //
    // Prepare a People Service authenticated client.
    final PeopleServiceApi peopleApi = PeopleServiceApi(client!);

    final request = await peopleApi.people.get(
      'people/me',
      personFields: 'names,genders,birthdays',
    );
    final person = request;
    if (person.names != null && person.names!.first.displayName != null) {
      name =
          "${person.names!.first.displayName}";
    }
    if (person.birthdays != null && person.birthdays!.first.date != null) {
      birthday =
          "${person.birthdays!.first.date!.year!}-${person.birthdays!.first.date!.month!}-${person.birthdays!.first.date!.day!}";
    }
    if (person.genders != null &&
        person.genders!.first.formattedValue != null) {
      gender = person.genders!.first.formattedValue;
    }

    setState(() {

    });
  }

  Future<void> _handleAuthorizeScopes() async {
    final bool isAuthorized = await _googleSignIn.requestScopes(scopes);
    setState(() {
      _isAuthorized = isAuthorized;
    });
    if (isAuthorized) {
      unawaited(_handleGetContact());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
           name != null ? Text(
              'Hi, $name',
            ) : Container(),
           gender != null || birthday != null ?  Text(
              'Your Gender: $gender And Birthday is $birthday',
            ) : Container(),


           name == null ? ElevatedButton(
              onPressed: _handleAuthorizeScopes,
              child: const Text('REQUEST YOUR INFO'),
            ) : Container(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () async => await _googleSignIn.signIn(),
            tooltip: 'Login',
            child: const Icon(Icons.login),
          ),
          const SizedBox(
            height: 16,
          ),
          FloatingActionButton(
            onPressed: () async => await _googleSignIn.signOut(),
            tooltip: 'Logout',
            child: const Icon(Icons.logout),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
