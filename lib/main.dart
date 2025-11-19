import 'package:apnea_app/pages/create_profile/create_profile.dart';
import 'package:apnea_app/pages/home/home.dart';
import 'package:apnea_app/pages/select_profile/select_profile.dart';
import 'package:flutter/material.dart';
import 'pages/splash/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ApneaApp());
}

class ApneaApp extends StatelessWidget{
  const ApneaApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'MomoTrustDisplay',
        brightness: Brightness.light,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash' : (context) => Splash(),
        '/create_profile' : (context) => CreateProfile(),
        '/select_profile' : (context) => SelectProfile(),
        '/home' : (context) => Home(profile: ModalRoute.of(context)!.settings.arguments as dynamic),
      },
    );
  }
}