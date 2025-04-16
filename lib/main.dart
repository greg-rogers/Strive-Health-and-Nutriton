import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_testing/screens/publicprofile.dart';
import 'firebase_options.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/home.dart';
import 'screens/workout.dart';
import 'screens/feed.dart';
import 'screens/profile.dart';
import 'screens/notifications.dart';
import 'screens/searchusers.dart';


final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness App',
      navigatorObservers: [routeObserver],
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/workout': (context) => WorkoutScreen(),
        '/profile': (context) => ProfileScreen(),
        '/feed': (context) => FeedScreen(),
        '/notifications' : (context) => NotificationsScreen(),
        '/search' : (context) => SearchUsersScreen(),
        '/publicprofile': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return PublicProfileScreen(userId: userId);
        },
         
        

      },
    );
  }
}

