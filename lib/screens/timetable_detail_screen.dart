import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class TimetableDetailScreen extends StatefulWidget {
  final Map<String, dynamic> timetable;
  const TimetableDetailScreen({super.key, required this.timetable});

  @override
  State<TimetableDetailScreen> createState() => _TimetableDetailScreenState();
}

class _TimetableDetailScreenState extends State<TimetableDetailScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  final List<String> _days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await DatabaseHelper.fetchTimetableEntries(widget.timetable['id']);
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  void _showAddClassDialog(int dayIndex) {
    final subjectController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Add Class to ${_days[dayIndex]}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: subjectController, decoration: const InputDecoration(labelText: "Subject / Class Name")),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(startTime.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: startTime);
                      if (t != null) setStateDialog(() => startTime = t);
                    },
                  ),
                  const Text("to"),
                  TextButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(endTime.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: endTime);
                      if (t != null) setStateDialog(() => endTime = t);
                    },
                  ),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (subjectController.text.isNotEmpty) {
                  String formattedStart = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
                  String formattedEnd = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
                  
                  await DatabaseHelper.saveTimetableEntry(
                    widget.timetable['id'], dayIndex + 1, 
                    subjectController.text, formattedStart, formattedEnd
                  );
                  if (context.mounted) Navigator.pop(context);
                  _loadEntries();
                }
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.timetable['title']),
          bottom: TabBar(
            isScrollable: true,
            tabs: _days.map((day) => Tab(text: day)).toList(),
          ),
        ),
        // 👇 Wrapped the body in SafeArea to protect the bottom button 👇
        body: SafeArea(
          bottom: true,
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: List.generate(7, (index) {
                  final dayEntries = _entries.where((e) => e['day_of_week'] == (index + 1)).toList();
                  
                  return Column(
                    children: [
                      Expanded(
                        child: dayEntries.isEmpty 
                          ? const Center(child: Text("No classes scheduled.", style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: dayEntries.length,
                              itemBuilder: (context, i) {
                                final entry = dayEntries[i];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.class_, color: Colors.teal),
                                    title: Text(entry['subject'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("${entry['start_time']} - ${entry['end_time']}"),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () async {
                                        await DatabaseHelper.deleteTimetableEntry(entry['id']);
                                        _loadEntries();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                      Padding(
                        // 👇 Adjusted padding to give it breathing room above the nav bar 👇
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 24.0), 
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddClassDialog(index),
                          icon: const Icon(Icons.add),
                          label: Text("Add Class to ${_days[index]}"),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        ),
                      )
                    ],
                  );
                }),
              ),
        ),
      ),
    );
  }
}