import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'env.dart';

Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode && Env.useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(Env.authHost, Env.authPort);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false, sslEnabled: false);
  }
}
