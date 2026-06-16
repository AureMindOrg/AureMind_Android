import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class NoteFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingNote; 
  const NoteFormScreen({super.key, this.existingNote});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _isEditing = true;
      _titleController.text = widget.existingNote!['title'] ?? '';
      _bodyController.text = widget.existingNote!['decrypted_content'] ?? '';
    }
  }

  void _saveNote() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and body cannot be empty')));
      return;
    }

    if (_isEditing) {
      await DatabaseHelper.updateNote(widget.existingNote!['id'], _titleController.text, _bodyController.text);
    } else {
      await DatabaseHelper.saveNoteToLocalDevice(title: _titleController.text, body: _bodyController.text);
    }
    
    if (mounted) Navigator.pop(context, true); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'New Note', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveNote)
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(hintText: "Title", border: InputBorder.none),
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(hintText: "Start typing...", border: InputBorder.none),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}