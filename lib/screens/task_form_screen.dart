import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/notification_helper.dart';

class TaskFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingTask; 
  const TaskFormScreen({super.key, this.existingTask});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _customMinutesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isEditing = false;
  
  int _selectedReminderValue = 0; 
  final Map<int, String> _reminderOptions = {
    0: "No Reminder", 5: "5 Minutes Before", 15: "15 Minutes Before",
    60: "1 Hour Before", 1440: "1 Day Before", -1: "Custom Minutes",
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _isEditing = true;
      _titleController.text = widget.existingTask!['title'];
      DateTime dt = DateTime.parse(widget.existingTask!['due_date']);
      _selectedDate = dt;
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      
      int reminder = widget.existingTask!['reminder_minutes'] ?? 0;
      if (_reminderOptions.containsKey(reminder)) {
        _selectedReminderValue = reminder;
      } else {
        _selectedReminderValue = -1;
        _customMinutesController.text = reminder.toString();
      }
    }
  }

  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context, initialDate: _selectedDate ?? DateTime.now(), 
      firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2100),
    );
    if (date != null) {
      TimeOfDay? time = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
      if (time != null) {
        setState(() { _selectedDate = date; _selectedTime = time; });
      }
    }
  }

  void _saveTask() async {
    if (_titleController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      final dueDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
      int finalReminderMinutes = _selectedReminderValue == -1 ? (int.tryParse(_customMinutesController.text) ?? 0) : _selectedReminderValue;

      int taskId;
      if (_isEditing) {
        taskId = widget.existingTask!['id'];
        await NotificationHelper.cancelNotification(taskId); // Cancel old alarm
        await DatabaseHelper.updateTaskDetails(taskId, _titleController.text, dueDateTime, finalReminderMinutes);
      } else {
        taskId = await DatabaseHelper.saveTask(_titleController.text, dueDateTime, finalReminderMinutes);
      }
      
      if (finalReminderMinutes > 0) {
        DateTime scheduleTime = dueDateTime.subtract(Duration(minutes: finalReminderMinutes));
        if (scheduleTime.isAfter(DateTime.now())) {
          await NotificationHelper.scheduleTaskNotification(taskId, _titleController.text, scheduleTime);
        }
      }
    } catch (e) {
      debugPrint("Task Save Error: $e");
    }
    
    if (mounted) Navigator.pop(context, true); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Edit Task" : "Create New Task")),
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
              label: Text(_selectedDate == null ? "Select Due Date & Time" : "Due: ${_selectedDate!.toLocal().toString().split(' ')[0]} ${_selectedTime!.format(context)}"),
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
              child: const Text("Save Task", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}