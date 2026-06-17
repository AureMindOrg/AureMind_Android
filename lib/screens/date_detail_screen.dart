import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateDetailScreen extends StatefulWidget {
  final DateTime initialDate;
  final List<Map<String, dynamic>> dayItems;
  const DateDetailScreen({super.key, required this.initialDate, required this.dayItems});

  @override
  State<DateDetailScreen> createState() => _DateDetailScreenState();
}

class _DateDetailScreenState extends State<DateDetailScreen> {
  @override
  Widget build(BuildContext context) {
    String displayDate = DateFormat('EEEE, MMM d, yyyy').format(widget.initialDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Day View')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(displayDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.dayItems.isEmpty
                ? const Center(child: Text("Nothing scheduled for this day.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.dayItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.dayItems[index];
                      
                      if (item['type'] == 'task') {
                        bool isCompleted = item['is_completed'] == 1;
                        DateTime dt = DateTime.parse(item['due_date']);
                        
                        // 👇 Uses Custom Folder Color!
                        Color iconColor = isCompleted 
                            ? Colors.green 
                            : (item['folder_color'] != null ? Color(item['folder_color']) : Theme.of(context).colorScheme.primary);
                            
                        return Card(
                          child: ListTile(
                            leading: Icon(isCompleted ? Icons.check_circle : Icons.check_box_outline_blank, color: iconColor),
                            title: Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                            subtitle: Text("Task Due at ${DateFormat('h:mm a').format(dt)}"),
                          ),
                        );
                      } 
                      else if (item['type'] == 'event') {
                        // 👇 Uses Custom Folder Color!
                        Color iconColor = item['folder_color'] != null ? Color(item['folder_color']) : Colors.orange;
                        
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.event, color: iconColor),
                            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item['description'] ?? 'Event'),
                          ),
                        );
                      }
                      else if (item['type'] == 'class') {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.class_, color: Colors.teal),
                            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Class Time: ${item['time']}"),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}