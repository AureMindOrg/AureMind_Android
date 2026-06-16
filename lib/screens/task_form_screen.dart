import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/notification_helper.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _customMinutesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  int _selectedReminderValue = 0; 
  final Map<int, String> _reminderOptions = {
    0: "No Reminder",
    5: "5 Minutes Before",
    15: "15 Minutes Before",
    60: "1 Hour Before",
    1440: "1 Day Before",
    -1: "Custom Minutes",
  };

  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context, 
      initialDate: DateTime.now(), 
      firstDate: DateTime.now(), 
      lastDate: DateTime(2100),
    );
    if (date != null) {
      TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() { _selectedDate = date; _selectedTime = time; });
      }
    }
  }

  void _saveTask() async {
    // 1. Validate Form
    if (_titleController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    // 2. Safe Database & Notification Execution
    try {
      final dueDateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );

      int finalReminderMinutes = _selectedReminderValue;
      if (_selectedReminderValue == -1) {
        finalReminderMinutes = int.tryParse(_customMinutesController.text) ?? 0;
      }

      int taskId = await DatabaseHelper.saveTask(_titleController.text, dueDateTime, finalReminderMinutes);
      
      // Schedule Notification safely
      if (finalReminderMinutes > 0) {
        DateTime scheduleTime = dueDateTime.subtract(Duration(minutes: finalReminderMinutes));
        if (scheduleTime.isAfter(DateTime.now())) {
          await NotificationHelper.scheduleTaskNotification(taskId, _titleController.text, scheduleTime);
        }
      }
    } catch (e) {
      debugPrint("Task Save Error: $e");
      // Even if an error happens in the background, we let the user proceed
    }
    
    // 3. Guarantee Navigation Back
    if (!mounted) return;
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Task")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Task Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.calendar_today),
              label: Text(_selectedDate == null 
                  ? "Select Due Date & Time" 
                  : "Due: ${_selectedDate!.toLocal().toString().split(' ')[0]} ${_selectedTime!.format(context)}"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedReminderValue,
              decoration: const InputDecoration(labelText: "Reminder", border: OutlineInputBorder()),
              items: _reminderOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (val) => setState(() => _selectedReminderValue = val!),
            ),
            if (_selectedReminderValue == -1) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Minutes before due date", border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
              child: const Text("Save Task", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}