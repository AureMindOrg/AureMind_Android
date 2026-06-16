import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'notes_screen.dart';
import 'tasks_screen.dart';
import 'calendar_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const NotesScreen(),
    const TasksScreen(),
    const CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.sticky_note_2), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        ],
      ),
    );
  }
}