import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';

class DateDetailScreen extends StatefulWidget {
  final DateTime initialDate;
  const DateDetailScreen({super.key, required this.initialDate});

  @override
  State<DateDetailScreen> createState() => _DateDetailScreenState();
}

class _DateDetailScreenState extends State<DateDetailScreen> {
  late DateTime _currentDate;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final allTasks = await DatabaseHelper.fetchAllTasks();
    setState(() {
      _tasks = allTasks.where((t) {
        DateTime dt = DateTime.parse(t['due_date']);
        return dt.year == _currentDate.year && dt.month == _currentDate.month && dt.day == _currentDate.day;
      }).toList();
      _isLoading = false;
    });
  }

  void _changeDate(int days) {
    setState(() { _currentDate = _currentDate.add(Duration(days: days)); });
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    String displayDate = DateFormat('EEEE, MMM d, yyyy').format(_currentDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Day View')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0), color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blue), onPressed: () => _changeDate(-1)),
                Text(displayDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue), onPressed: () => _changeDate(1)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
                ? const Center(child: Text("No tasks for this day.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      DateTime dt = DateTime.parse(task['due_date']);
                      String time = DateFormat('h:mm a').format(dt);
                      bool isCompleted = task['is_completed'] == 1;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(isCompleted ? Icons.check_circle : Icons.access_time, color: isCompleted ? Colors.green : Colors.blue),
                          title: Text(task['title'], style: TextStyle(fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                          subtitle: Text("Due at $time"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}