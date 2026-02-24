import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //import necessario
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //necessario prima di SystemChrome
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}