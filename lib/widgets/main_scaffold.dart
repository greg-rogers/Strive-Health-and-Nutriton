import 'package:flutter/material.dart';
import '/screens/screens.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  final Widget? overridePage;

  const MainScaffold({
    super.key,
    this.initialIndex = 0,
    this.overridePage,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    WorkoutScreen(),
    Center(child: Text("🥗 Nutrition", style: TextStyle(fontSize: 22))),
    FeedScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool usingOverride = widget.overridePage != null;

    return Scaffold(
      body: usingOverride ? widget.overridePage! : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (usingOverride) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MainScaffold(initialIndex: index),
              ),
            );
          } else {
            _onTabTapped(index);
          }
        },
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
