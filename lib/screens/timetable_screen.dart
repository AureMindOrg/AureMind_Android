import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/app_drawer.dart';
import 'timetable_detail_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  Set<int> _selectedIds = {};

  void _refreshTimetables() => setState(() { _selectedIds.clear(); });
  void _deleteSelected() async { await DatabaseHelper.deleteTimetables(_selectedIds.toList()); _refreshTimetables(); }
  void _toggleSelection(int id) { setState(() { _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id); }); }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    DateTime startDate = DateTime.now(); DateTime endDate = DateTime.now().add(const Duration(days: 90));
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Create Timetable"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Name (e.g. Fall Semester)")),
              const SizedBox(height: 16),
              ListTile(title: const Text("Start Date"), subtitle: Text(startDate.toString().split(' ')[0]), trailing: const Icon(Icons.calendar_month), onTap: () async { final d = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setStateDialog(() => startDate = d); }),
              ListTile(title: const Text("End Date"), subtitle: Text(endDate.toString().split(' ')[0]), trailing: const Icon(Icons.calendar_month), onTap: () async { final d = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setStateDialog(() => endDate = d); }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () async { if (titleController.text.isNotEmpty) { await DatabaseHelper.saveTimetable(titleController.text, startDate, endDate); if (context.mounted) Navigator.pop(context); _refreshTimetables(); } }, child: const Text("Save"))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(currentRoute: 'Timetable'), // Right Side
      appBar: AppBar(
        title: Text(_selectedIds.isEmpty ? 'Time Table Manager' : '${_selectedIds.length} Selected'),
        actions: [
          if (_selectedIds.isNotEmpty) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelected),
          // 👇 Manually adding the Right Menu button back! 👇
          Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openEndDrawer())),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.fetchTimetables(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final timetables = snapshot.data!;
            if (timetables.isEmpty) return const Center(child: Text("No timetables found."));

            return ListView.builder(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 85),
              itemCount: timetables.length,
              itemBuilder: (context, index) {
                final tt = timetables[index];
                final isSelected = _selectedIds.contains(tt['id']);
                String start = tt['start_date'] != null ? tt['start_date'].toString().split('T')[0] : 'No Start';
                String end = tt['end_date'].toString().split('T')[0];

                return Card(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                  shape: RoundedRectangleBorder(side: BorderSide(color: isSelected ? Colors.teal : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    onLongPress: () => _toggleSelection(tt['id']),
                    onTap: () { if (_selectedIds.isNotEmpty) { _toggleSelection(tt['id']); } else { Navigator.push(context, MaterialPageRoute(builder: (context) => TimetableDetailScreen(timetable: tt))); } },
                    leading: const Icon(Icons.table_chart, color: Colors.teal),
                    title: Text(tt['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("$start  to  $end"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: _selectedIds.isEmpty ? FloatingActionButton(onPressed: _showCreateDialog, backgroundColor: Colors.teal, child: const Icon(Icons.add, color: Colors.white)) : null,
    );
  }
}