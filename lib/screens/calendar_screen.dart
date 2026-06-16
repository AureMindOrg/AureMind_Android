import 'dart:collection'; 
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
  
  LinkedHashMap<DateTime, List<Map<String, dynamic>>> _itemsByDay = LinkedHashMap(
    equals: (a, b) => isSameDay(a, b),
    hashCode: (DateTime key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

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
    
    final grouped = LinkedHashMap<DateTime, List<Map<String, dynamic>>>(
      equals: (a, b) => isSameDay(a, b),
      hashCode: (DateTime key) => key.day * 1000000 + key.month * 10000 + key.year,
    );

    // 👇 FIXED: Clone the Task into a mutable map before modifying it 👇
    for (var task in tasks) {
      try {
        DateTime dt = DateTime.parse(task['due_date'].toString());
        DateTime normalized = DateTime.utc(dt.year, dt.month, dt.day); 
        Map<String, dynamic> mutableTask = Map<String, dynamic>.from(task); // Clone it!
        mutableTask['type'] = 'task'; 
        grouped.putIfAbsent(normalized, () => []).add(mutableTask);
      } catch (e) {
        debugPrint("Task Error: $e");
      }
    }
    
    // 👇 FIXED: Clone the Event into a mutable map before modifying it 👇
    for (var event in events) {
      try {
        DateTime dt = DateTime.parse(event['event_date'].toString());
        DateTime normalized = DateTime.utc(dt.year, dt.month, dt.day); 
        Map<String, dynamic> mutableEvent = Map<String, dynamic>.from(event); // Clone it!
        mutableEvent['type'] = 'event'; 
        grouped.putIfAbsent(normalized, () => []).add(mutableEvent);
      } catch (e) {
        debugPrint("Event Error: $e");
      }
    }

    // Inject Timetable Classes
    for (var tt in timetables) {
      try {
        if (tt['start_date'] == null || tt['start_date'].toString() == 'null') continue; 
        DateTime start = DateTime.parse(tt['start_date'].toString());
        DateTime end = DateTime.parse(tt['end_date'].toString());
        final entries = await DatabaseHelper.fetchTimetableEntries(tt['id']);
        
        for (DateTime d = start; d.isBefore(end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
          DateTime normalized = DateTime.utc(d.year, d.month, d.day);
          int weekday = d.weekday; 
          
          var classesForThisDay = entries.where((e) => e['day_of_week'] == weekday).toList();
          for (var c in classesForThisDay) {
            grouped.putIfAbsent(normalized, () => []).add({
              'type': 'class',
              'title': c['subject'],
              'time': '${c['start_time']} - ${c['end_time']}'
            });
          }
        }
      } catch (e) {
        debugPrint("Timetable Error: $e");
      }
    }

    if (mounted) {
      setState(() { _itemsByDay = grouped; });
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime normalizedDate = DateTime.utc(day.year, day.month, day.day);
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
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            TableCalendar<Map<String, dynamic>>(
              rowHeight: 80, // BIG CALENDAR
              firstDay: DateTime.utc(2020, 1, 1), 
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay, 
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
                Navigator.push(context, MaterialPageRoute(builder: (context) => DateDetailScreen(initialDate: selectedDay, dayItems: _getEventsForDay(selectedDay))))
                  .then((_) => _loadCalendarData()); 
              },
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarBuilders: CalendarBuilders<Map<String, dynamic>>(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox();
                  return Positioned(
                    bottom: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: events.take(2).map((e) {
                        Color c = e['type'] == 'task' ? Colors.blue : e['type'] == 'event' ? Colors.orange : Colors.teal;
                        return Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
                          constraints: const BoxConstraints(maxWidth: 45),
                          child: Text(
                            e['title'].toString(),
                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              ),
            ),
            const Expanded(child: Center(child: Text("Tap on a date to see its schedule.", style: TextStyle(color: Colors.grey))))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
    );
  }
}