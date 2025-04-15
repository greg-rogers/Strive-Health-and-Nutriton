import 'package:flutter/material.dart';
import 'workout.dart';
import 'feed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text("🏠 Home", style: TextStyle(fontSize: 22))),
    WorkoutScreen(),
    Center(child: Text("🥗 Nutrition", style: TextStyle(fontSize: 22))),
    FeedScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🔔 Notifications tapped")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Strive', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: _openNotifications,
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Feed'),
        ],
      ),
    );
  }
}
