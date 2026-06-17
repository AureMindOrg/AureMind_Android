import 'dart:collection'; 
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_helper.dart';
import '../services/ics_helper.dart';
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
  
  bool _showTasks = true;
  bool _showEvents = true;
  bool _showClasses = true;

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
    
    // 👇 Fetch all folder colors to paint the calendar items correctly!
    final taskFolders = await DatabaseHelper.fetchFolders('task');
    final eventFolders = await DatabaseHelper.fetchFolders('event');
    Map<int, int> folderColors = {};
    for (var f in [...taskFolders, ...eventFolders]) {
      if (f['color'] != null) {
        folderColors[f['id'] as int] = int.parse(f['color'].toString());
      }
    }

    final grouped = LinkedHashMap<DateTime, List<Map<String, dynamic>>>(
      equals: (a, b) => isSameDay(a, b),
      hashCode: (DateTime key) => key.day * 1000000 + key.month * 10000 + key.year,
    );

    if (_showTasks) {
      for (var task in tasks) {
        try {
          DateTime dt = DateTime.parse(task['due_date'].toString());
          DateTime normalized = DateTime.utc(dt.year, dt.month, dt.day); 
          Map<String, dynamic> mutableTask = Map<String, dynamic>.from(task); 
          mutableTask['type'] = 'task'; 
          // Inject folder color into the task
          mutableTask['folder_color'] = task['folder_id'] != null ? folderColors[task['folder_id']] : null;
          grouped.putIfAbsent(normalized, () => []).add(mutableTask);
        } catch (_) {}
      }
    }
    
    if (_showEvents) {
      for (var event in events) {
        try {
          DateTime dt = DateTime.parse(event['event_date'].toString());
          DateTime normalized = DateTime.utc(dt.year, dt.month, dt.day); 
          Map<String, dynamic> mutableEvent = Map<String, dynamic>.from(event);
          mutableEvent['type'] = 'event'; 
          // Inject folder color into the event
          mutableEvent['folder_color'] = event['folder_id'] != null ? folderColors[event['folder_id']] : null;
          grouped.putIfAbsent(normalized, () => []).add(mutableEvent);
        } catch (_) {}
      }
    }

    if (_showClasses) {
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
                'type': 'class', 'title': c['subject'], 'time': '${c['start_time']} - ${c['end_time']}'
              });
            }
          }
        } catch (_) {}
      }
    }

    if (mounted) setState(() { _itemsByDay = grouped; });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime normalizedDate = DateTime.utc(day.year, day.month, day.day);
    return _itemsByDay[normalizedDate] ?? [];
  }

  void _exportEventsFlow() async {
    final folders = await DatabaseHelper.fetchFolders('event');
    int? selectedFolderId;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Export Events"),
          content: DropdownButtonFormField<int?>(
            value: selectedFolderId,
            decoration: const InputDecoration(labelText: "Select Event Folder"),
            items: [
              const DropdownMenuItem(value: null, child: Text("Root Directory (Uncategorized)")),
              ...folders.map((f) => DropdownMenuItem(value: f['id'] as int?, child: Text(f['name']))),
            ],
            onChanged: (val) => setStateDialog(() => selectedFolderId = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final events = await DatabaseHelper.fetchAllEvents(folderId: selectedFolderId);
                if (events.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No events found in this folder.")));
                  return;
                }
                String fName = selectedFolderId == null ? "Root" : folders.firstWhere((f) => f['id'] == selectedFolderId)['name'];
                await IcsHelper.exportEvents(events, fName);
              },
              child: const Text("Export .ics"),
            ),
          ],
        ),
      ),
    );
  }

  void _exportTimetableFlow() async {
    final timetables = await DatabaseHelper.fetchTimetables();
    if (timetables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No timetables exist yet.")));
      return;
    }

    int? selectedTtId = timetables.first['id'];

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Export Timetable"),
          content: DropdownButtonFormField<int>(
            value: selectedTtId,
            decoration: const InputDecoration(labelText: "Select Timetable"),
            items: timetables.map((tt) => DropdownMenuItem(value: tt['id'] as int, child: Text(tt['title']))).toList(),
            onChanged: (val) => setStateDialog(() => selectedTtId = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final tt = timetables.firstWhere((t) => t['id'] == selectedTtId);
                final entries = await DatabaseHelper.fetchTimetableEntries(selectedTtId!);
                if (entries.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No classes scheduled in this timetable.")));
                  return;
                }
                await IcsHelper.exportTimetable(tt, entries);
              },
              child: const Text("Export .ics"),
            ),
          ],
        ),
      ),
    );
  }

  void _importEventsFlow() async {
    final folders = await DatabaseHelper.fetchFolders('event');
    int? selectedFolderId;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Import Events (.ics)"),
          content: DropdownButtonFormField<int?>(
            value: selectedFolderId,
            decoration: const InputDecoration(labelText: "Save into Folder"),
            items: [
              const DropdownMenuItem(value: null, child: Text("Root Directory")),
              ...folders.map((f) => DropdownMenuItem(value: f['id'] as int?, child: Text(f['name']))),
            ],
            onChanged: (val) => setStateDialog(() => selectedFolderId = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['ics']);
                if (result != null && result.files.single.path != null) {
                  final newEvents = await IcsHelper.parseIcsFile(result.files.single.path!);
                  for (var e in newEvents) {
                    await DatabaseHelper.saveEvent(e['title'], e['description'], e['event_date'], folderId: selectedFolderId);
                  }
                  _loadCalendarData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Imported ${newEvents.length} events!")));
                }
              },
              child: const Text("Select File"),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportExportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text("Sync external calendars", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            ListTile(leading: const Icon(Icons.upload_file, color: Colors.blue), title: const Text('Export Events to .ics'), onTap: () { Navigator.pop(context); _exportEventsFlow(); }),
            ListTile(leading: const Icon(Icons.school, color: Colors.teal), title: const Text('Export Timetable to .ics'), onTap: () { Navigator.pop(context); _exportTimetableFlow(); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.download, color: Colors.orange), title: const Text('Import .ics to Events'), onTap: () { Navigator.pop(context); _importEventsFlow(); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(currentRoute: 'Calendar'), 
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.import_export), tooltip: 'Import/Export', onPressed: _showImportExportMenu),
          Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openEndDrawer())),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilterChip(label: const Text('Tasks', style: TextStyle(fontSize: 12)), selected: _showTasks, selectedColor: Colors.blue.withOpacity(0.2), checkmarkColor: Colors.blue, onSelected: (v) { setState(() { _showTasks = v; _loadCalendarData(); }); }),
                  FilterChip(label: const Text('Events', style: TextStyle(fontSize: 12)), selected: _showEvents, selectedColor: Colors.orange.withOpacity(0.2), checkmarkColor: Colors.orange, onSelected: (v) { setState(() { _showEvents = v; _loadCalendarData(); }); }),
                  FilterChip(label: const Text('Classes', style: TextStyle(fontSize: 12)), selected: _showClasses, selectedColor: Colors.teal.withOpacity(0.2), checkmarkColor: Colors.teal, onSelected: (v) { setState(() { _showClasses = v; _loadCalendarData(); }); }),
                ],
              ),
            ),
            TableCalendar<Map<String, dynamic>>(
              rowHeight: 80, 
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
                        
                        // 👇 Uses custom folder color if assigned, otherwise falls back to defaults! 👇
                        Color c;
                        if (e['folder_color'] != null) {
                          c = Color(e['folder_color']);
                        } else {
                          c = e['type'] == 'task' ? Colors.blue : e['type'] == 'event' ? Colors.orange : Colors.teal;
                        }

                        return Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
                          constraints: const BoxConstraints(maxWidth: 45),
                          child: Text(e['title'].toString(), style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5), shape: BoxShape.circle), selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
            ),
            const Expanded(child: Center(child: Text("Tap on a date to see its schedule.", style: TextStyle(color: Colors.grey))))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(leading: const Icon(Icons.check_box, color: Colors.blue), title: const Text('Add Task'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskFormScreen())).then((_) => _loadCalendarData()); }),
                  ListTile(leading: const Icon(Icons.event, color: Colors.orange), title: const Text('Add Event'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => EventFormScreen(initialDate: _selectedDay))).then((_) => _loadCalendarData()); }),
                ],
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
    );
  }
}