import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/notification_helper.dart';
import '../widgets/app_drawer.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Set<int> _selectedIds = {};

  void _refreshTasks() {
    setState(() { _selectedIds.clear(); });
  }

  void _deleteSelected() async {
    for (int id in _selectedIds) {
      await NotificationHelper.cancelNotification(id); 
    }
    await DatabaseHelper.deleteTasks(_selectedIds.toList());
    _refreshTasks();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleTaskCompletion(Map<String, dynamic> task, bool? isCompleted) async {
    await DatabaseHelper.updateTaskStatus(task['id'], isCompleted == true ? 1 : 0);
    if (isCompleted == true) {
      await NotificationHelper.cancelNotification(task['id']); 
    }
    _refreshTasks();
  }

  Widget _buildTaskTile(Map<String, dynamic> task, bool isCompletedTask) {
    DateTime dueDate = DateTime.parse(task['due_date']);
    String formattedDate = "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')} ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}";
    final isSelected = _selectedIds.contains(task['id']);

    return Card(
      elevation: 2,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
      ),
      child: ListTile(
        onLongPress: () => _toggleSelection(task['id']),
        onTap: () {
          if (_selectedIds.isNotEmpty) _toggleSelection(task['id']);
        },
        leading: Checkbox(
          value: task['is_completed'] == 1,
          activeColor: Colors.green,
          onChanged: (val) {
            if (_selectedIds.isEmpty) _toggleTaskCompletion(task, val);
          },
        ),
        title: Text(
          task['title'], 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            decoration: isCompletedTask ? TextDecoration.lineThrough : null,
            color: isCompletedTask ? Colors.grey : Colors.black
          )
        ),
        subtitle: Text("Due: $formattedDate", style: const TextStyle(color: Colors.blueGrey)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'Tasks'),
      appBar: AppBar(
        title: Text(_selectedIds.isEmpty ? 'Tasks' : '${_selectedIds.length} Selected', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelected)
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.fetchAllTasks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            final tasks = snapshot.data ?? [];
            final pendingTasks = tasks.where((t) => t['is_completed'] == 0).toList();
            final completedTasks = tasks.where((t) => t['is_completed'] == 1).toList();

            if (tasks.isEmpty) {
              return const Center(child: Text("No tasks found. Create one to get started! 🥳"));
            }

            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 85), // Fix for bottom overlap
              children: [
                ...pendingTasks.map((t) => _buildTaskTile(t, false)),
                
                if (completedTasks.isNotEmpty)
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text("Completed (${completedTasks.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      initiallyExpanded: false,
                      children: completedTasks.map((t) => _buildTaskTile(t, true)).toList(),
                    ),
                  )
              ],
            );
          },
        ),
      ),
      floatingActionButton: _selectedIds.isEmpty ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskFormScreen()));
          _refreshTasks(); 
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}