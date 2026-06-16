import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/app_drawer.dart';
import 'event_form_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  Set<int> _selectedIds = {};

  void _refreshEvents() => setState(() { _selectedIds.clear(); });

  void _deleteSelected() async {
    await DatabaseHelper.deleteEvents(_selectedIds.toList());
    _refreshEvents();
  }

  void _toggleSelection(int id) {
    setState(() {
      _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'Events'),
      appBar: AppBar(
        title: Text(_selectedIds.isEmpty ? 'Events' : '${_selectedIds.length} Selected', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelected)
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.fetchAllEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final events = snapshot.data ?? [];
            if (events.isEmpty) return const Center(child: Text("No upcoming events."));

            return ListView.builder(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 85), 
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isSelected = _selectedIds.contains(event['id']);
                DateTime date = DateTime.parse(event['event_date']);

                return Card(
                  // Set to null to absorb system theme properly
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    onLongPress: () => _toggleSelection(event['id']),
                    onTap: () {
                      if (_selectedIds.isNotEmpty) _toggleSelection(event['id']);
                    },
                    leading: const Icon(Icons.event, color: Colors.orange),
                    title: Text(event['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n${event['description']}"),
                    isThreeLine: event['description'].toString().isNotEmpty,
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: _selectedIds.isEmpty ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const EventFormScreen()));
          _refreshEvents();
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}