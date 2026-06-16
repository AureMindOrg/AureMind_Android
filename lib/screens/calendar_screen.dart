import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_helper.dart';
import 'date_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _tasksByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper.fetchAllTasks();
    Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (var task in tasks) {
      DateTime dt = DateTime.parse(task['due_date']);
      DateTime normalizedDate = DateTime(dt.year, dt.month, dt.day); 
      
      if (grouped[normalizedDate] == null) grouped[normalizedDate] = [];
      grouped[normalizedDate]!.add(task);
    }

    setState(() { _tasksByDay = grouped; });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime normalizedDate = DateTime(day.year, day.month, day.day);
    return _tasksByDay[normalizedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1), 
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay, 
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
              Navigator.push(context, MaterialPageRoute(builder: (context) => DateDetailScreen(initialDate: selectedDay)))
                .then((_) => _loadTasks()); 
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, 
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            ),
          ),
          const Expanded(child: Center(child: Text("Tap on a date to see its tasks.", style: TextStyle(color: Colors.grey))))
        ],
      ),
    );
  }
}