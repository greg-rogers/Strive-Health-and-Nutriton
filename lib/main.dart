import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/screens.dart';
import 'widgets/main_scaffold.dart';


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
        
        '/home': (context) => const MainScaffold(initialIndex: 0),
        '/workout': (context) => const MainScaffold(initialIndex: 1),
        '/feed': (context) => const MainScaffold(initialIndex: 2),
        '/profile': (context) => const MainScaffold(initialIndex: 3),

        '/notifications': (context) => const NotificationsScreen(),
        '/search': (context) => const SearchUsersScreen(),
        '/publicprofile': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return PublicProfileScreen(userId: userId);
        },
         
        

      },
    );
  }
}

