// ATENÇÃO: este é um arquivo placeholder.
//
// Gere o arquivo real com o FlutterFire CLI depois de criar o projeto no
// Firebase Console:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// O comando acima SUBSTITUI este arquivo automaticamente com as chaves
// corretas de cada plataforma (Android, iOS, Web). Não edite manualmente.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para esta plataforma. '
          'Rode `flutterfire configure`.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCFAZiPaKafE2c6uwMQXCToHxQuCiXxXdk',
    appId: '1:550569106445:web:6c7e8f360df37a6eb60944',
    messagingSenderId: '550569106445',
    projectId: 'fithome-6e8d1',
    authDomain: 'fithome-6e8d1.firebaseapp.com',
    storageBucket: 'fithome-6e8d1.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCFAZiPaKafE2c6uwMQXCToHxQuCiXxXdk',
    appId: '1:550569106445:web:6c7e8f360df37a6eb60944',
    messagingSenderId: '550569106445',
    projectId: 'fithome-6e8d1',
    storageBucket: 'fithome-6e8d1.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyCFAZiPaKafE2c6uwMQXCToHxQuCiXxXdk',
    appId: '1:550569106445:web:6c7e8f360df37a6eb60944',
    messagingSenderId: '550569106445',
    projectId: 'fithome-6e8d1',
    storageBucket: 'fithome-6e8d1.firebasestorage.app',
    iosBundleId: 'com.suaempresa.homeWorkoutApp',
  );
}
