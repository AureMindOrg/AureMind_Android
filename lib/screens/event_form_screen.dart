import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Map<String, dynamic>? existingEvent; 
  final int? folderId; // Added for folder routing
  const EventFormScreen({super.key, this.initialDate, this.existingEvent, this.folderId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate; bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      _isEditing = true;
      _titleController.text = widget.existingEvent!['title'];
      _descController.text = widget.existingEvent!['description'] ?? '';
      _selectedDate = DateTime.parse(widget.existingEvent!['event_date']);
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
    }
  }

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(context: context, initialDate: _selectedDate!, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (date != null) setState(() { _selectedDate = date; });
  }

  void _saveEvent() async {
    if (_titleController.text.isEmpty || _selectedDate == null) return;
    if (_isEditing) {
      await DatabaseHelper.updateEventDetails(widget.existingEvent!['id'], _titleController.text, _descController.text, _selectedDate!);
    } else {
      // 👇 Uses widget.folderId to save in correct directory! 👇
      await DatabaseHelper.saveEvent(_titleController.text, _descController.text, _selectedDate!, folderId: widget.folderId);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Edit Event" : "Create Event")),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Event Title", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: "Description (Optional)", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month), label: Text("Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}")),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _saveEvent, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)), child: const Text("Save Event", style: TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }
}