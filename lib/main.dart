import 'package:chatter_box/screens/auth.dart';
import 'package:chatter_box/screens/home.dart';
import 'package:chatter_box/screens/spalsh.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:chatter_box/firebase_options.dart';

void main() async {
  Gemini.init(apiKey: 'AIzaSyAfyVI6kjTY-lzus2iBKMqFOOBTI-SqjTo');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirbaseOptions.currentPlatform,
  );
  runApp(const App());
  FlutterNativeSplash.remove();
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 210, 214, 220)),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return const SplashScreen();
          }
          if (snapshot.hasData) { 
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
