import 'package:flutter/material.dart';
import 'note_form_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Map<String, dynamic> currentNote;

  @override
  void initState() {
    super.initState();
    currentNote = widget.note;
  }

  void _openEditor() async {
    final bool? wasUpdated = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => NoteFormScreen(existingNote: currentNote))
    );

    if (wasUpdated == true && mounted) {
      Navigator.pop(context, true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Note Detail"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Note',
            onPressed: _openEditor,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentNote['title'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(currentNote['decrypted_content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}