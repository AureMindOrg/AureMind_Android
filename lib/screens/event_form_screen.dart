import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime? initialDate;
  const EventFormScreen({super.key, this.initialDate});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context, 
      initialDate: _selectedDate!, 
      firstDate: DateTime(2000), 
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() { _selectedDate = date; });
    }
  }

  void _saveEvent() async {
    if (_titleController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a title and date")));
      return;
    }
    await DatabaseHelper.saveEvent(_titleController.text, _descController.text, _selectedDate!);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Event")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Event Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description (Optional)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text("Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}"),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
              child: const Text("Save Event", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}