import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/attachment_helper.dart';

class NoteFormScreen extends StatefulWidget {
  const NoteFormScreen({super.key});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  AttachmentResult? _selectedAttachment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Note")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Title')),
            const SizedBox(height: 16),
            TextField(controller: _contentController, decoration: const InputDecoration(hintText: 'Take a note...'), maxLines: 5),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await AttachmentHelper.pickAndSaveAttachment();
                if (result != null) {
                  setState(() { _selectedAttachment = result; });
                }
              },
              icon: const Icon(Icons.attach_file),
              label: Text(_selectedAttachment != null ? "Attached: ${_selectedAttachment!.originalName}" : "Add Attachment"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.saveNoteToLocalDevice(
                  title: _titleController.text,
                  body: _contentController.text,
                  attachment: _selectedAttachment,
                );
                if (!mounted) return;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text("Save Note"),
            ),
          ],
        ),
      ),
    );
  }
}