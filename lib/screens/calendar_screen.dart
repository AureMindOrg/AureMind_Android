import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_helper.dart';
import '../widgets/app_drawer.dart';
import 'date_detail_screen.dart';
import 'task_form_screen.dart';
import 'event_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _itemsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    final tasks = await DatabaseHelper.fetchAllTasks();
    final events = await DatabaseHelper.fetchAllEvents();
    final timetables = await DatabaseHelper.fetchTimetables();
    
    Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    // 1. Group Tasks
    for (var task in tasks) {
      DateTime dt = DateTime.parse(task['due_date']);
      DateTime normalizedDate = DateTime(dt.year, dt.month, dt.day); 
      if (grouped[normalizedDate] == null) grouped[normalizedDate] = [];
      task['type'] = 'task'; 
      grouped[normalizedDate]!.add(task);
    }
    
    // 2. Group Events
    for (var event in events) {
      DateTime dt = DateTime.parse(event['event_date']);
      DateTime normalizedDate = DateTime(dt.year, dt.month, dt.day); 
      if (grouped[normalizedDate] == null) grouped[normalizedDate] = [];
      event['type'] = 'event'; 
      grouped[normalizedDate]!.add(event);
    }

    // 3. Inject Timetable Classes
    for (var tt in timetables) {
      if (tt['start_date'] == null) continue; // Skip old corrupted data if any
      DateTime start = DateTime.parse(tt['start_date']);
      DateTime end = DateTime.parse(tt['end_date']);
      final entries = await DatabaseHelper.fetchTimetableEntries(tt['id']);
      
      // Loop through every day between the Timetable Start and End Date
      for (DateTime d = start; d.isBefore(end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
        DateTime normalized = DateTime(d.year, d.month, d.day);
        int weekday = d.weekday; // 1 = Monday, 7 = Sunday
        
        var classesForThisDay = entries.where((e) => e['day_of_week'] == weekday).toList();
        for (var c in classesForThisDay) {
          if (grouped[normalized] == null) grouped[normalized] = [];
          grouped[normalized]!.add({
            'type': 'class',
            'title': c['subject'],
            'time': '${c['start_time']} - ${c['end_time']}'
          });
        }
      }
    }

    setState(() { _itemsByDay = grouped; });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime normalizedDate = DateTime(day.year, day.month, day.day);
    return _itemsByDay[normalizedDate] ?? [];
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_box, color: Colors.blue),
                title: const Text('Add Task'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskFormScreen())).then((_) => _loadCalendarData());
                },
              ),
              ListTile(
                leading: const Icon(Icons.event, color: Colors.orange),
                title: const Text('Add Event'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EventFormScreen(initialDate: _selectedDay))).then((_) => _loadCalendarData());
                },
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'Calendar'),
      appBar: AppBar(title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1), lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay, selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
              Navigator.push(context, MaterialPageRoute(builder: (context) => DateDetailScreen(initialDate: selectedDay, dayItems: _getEventsForDay(selectedDay))))
                .then((_) => _loadCalendarData()); 
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            ),
          ),
          const Expanded(child: Center(child: Text("Tap on a date to see its schedule.", style: TextStyle(color: Colors.grey))))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}