import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(currentRoute: 'Dashboard'), // Menu moved to right!
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome to AureMind!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              const Text("Recent Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                // 👇 FIXED: Changed fetchAllNotes() to fetchNotes() 👇
                future: DatabaseHelper.fetchNotes(), 
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final notes = snapshot.data!.take(3).toList();
                  if (notes.isEmpty) return const Card(child: ListTile(title: Text("No notes yet.")));

                  return Column(
                    children: notes.map((note) => Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.note, color: Colors.blue),
                        title: Text(note['title'] ?? 'Untitled'),
                        subtitle: Text(note['decrypted_content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    )).toList(),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              const Text("Upcoming Pending Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.fetchAllTasks(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  
                  final pendingTasks = snapshot.data!.where((t) => t['is_completed'] == 0).take(3).toList();
                  if (pendingTasks.isEmpty) return const Card(child: ListTile(title: Text("No upcoming tasks.")));

                  return Column(
                    children: pendingTasks.map((task) => Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.schedule, color: Colors.orange),
                        title: Text(task['title'] ?? 'Untitled'),
                        subtitle: Text("Due: ${task['due_date'].toString().split('T')[0]}"), 
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}