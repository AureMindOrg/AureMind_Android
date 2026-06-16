import 'package:flutter/material.dart';

class NoteDetailScreen extends StatelessWidget {
  final Map<String, dynamic> note;
  
  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final hasAttachment = note['attachment_path'] != null && note['attachment_path'].toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Detail', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note['title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Created: ${note['created_at'].toString().split('T')[0]}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 30),
            Text(
              note['decrypted_content'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (hasAttachment) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note['attachment_name'],
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}