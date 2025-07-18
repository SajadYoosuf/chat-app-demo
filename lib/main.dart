import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/app_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/color_constants.dart';
import 'pages/pages.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDOpH3IIu45Hqmp3EG483K6QL-QXg0wSaw",
            authDomain: "chat-app-demo-6519d.firebaseapp.com",
            projectId: "chat-app-demo-6519d",
            storageBucket: "chat-app-demo-6519d.firebasestorage.app",
            messagingSenderId: "237052702780",
            appId: "1:237052702780:web:d246a28b440900b59a9339",
            measurementId: "G-VEJC2JT891"));
  } else {
    await Firebase.initializeApp();
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  MyApp({required this.prefs});

  final _firebaseFirestore = FirebaseFirestore.instance;
  final _firebaseStorage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            firebaseAuth: FirebaseAuth.instance,
            googleSignIn: GoogleSignIn(),
            prefs: this.prefs,
            firebaseFirestore: this._firebaseFirestore,
          ),
        ),
        Provider<SettingProvider>(
          create: (_) => SettingProvider(
            prefs: this.prefs,
            firebaseFirestore: this._firebaseFirestore,
            firebaseStorage: this._firebaseStorage,
          ),
        ),
        Provider<HomeProvider>(
          create: (_) => HomeProvider(
            firebaseFirestore: this._firebaseFirestore,
          ),
        ),
        Provider<ChatProvider>(
          create: (_) => ChatProvider(
            prefs: this.prefs,
            firebaseFirestore: this._firebaseFirestore,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: ColorConstants.themeColor,
        ),
        home: SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
