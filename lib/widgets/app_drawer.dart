import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/events_screen.dart';
import '../screens/timetable_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  void _navigateTo(BuildContext context, Widget screen, String routeName) {
    if (currentRoute == routeName) {
      Navigator.pop(context); 
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF3B82F6)),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.spa, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  // 👇 Changed to AureMind 👇
                  Text('AureMind', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), 
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentRoute == 'Dashboard',
            onTap: () => _navigateTo(context, const DashboardScreen(), 'Dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.sticky_note_2),
            title: const Text('Notes'),
            selected: currentRoute == 'Notes',
            onTap: () => _navigateTo(context, const NotesScreen(), 'Notes'),
          ),
          ListTile(
            leading: const Icon(Icons.check_box),
            title: const Text('Tasks'),
            selected: currentRoute == 'Tasks',
            onTap: () => _navigateTo(context, const TasksScreen(), 'Tasks'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Calendar'),
            selected: currentRoute == 'Calendar',
            onTap: () => _navigateTo(context, const CalendarScreen(), 'Calendar'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Events Manager'),
            selected: currentRoute == 'Events',
            onTap: () => _navigateTo(context, const EventsScreen(), 'Events'),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Time Table Manager'),
            selected: currentRoute == 'Timetable',
            onTap: () => _navigateTo(context, const TimetableScreen(), 'Timetable'),
          ),
        ],
      ),
    );
  }
}