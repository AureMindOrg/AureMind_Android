import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_helper.dart';

class NoteFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingNote; 
  final int? folderId;
  
  const NoteFormScreen({super.key, this.existingNote, this.folderId});

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

  // --- MARKDOWN INJECTION LOGIC ---
  void _insertMarkdown(String prefix, String suffix) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    
    // If no text is selected, just put the cursor between the tags
    if (selection.start == -1) {
      final newText = text + prefix + suffix;
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - suffix.length),
      );
      return;
    }

    // Wrap selected text in the markdown tags
    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length),
    );
  }

  void _insertImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      // Inject the local file path as a markdown image tag
      String path = result.files.single.path!.replaceAll('\\', '/');
      _insertMarkdown('![Attached Image]($path)', '');
    }
  }

  // --- COMMAND PALETTE LOGIC ---
  void _showCommandPalette(BuildContext context) {
    // Unfocus the keyboard momentarily so the bottom sheet has room
    FocusScope.of(context).unfocus(); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4, width: 40,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text("Command Palette", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.link, color: Colors.blue),
                        title: const Text("Reference Note"),
                        subtitle: const Text("[[Note Name]]"),
                        onTap: () { Navigator.pop(context); _insertMarkdown('[[', ']]'); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.code, color: Colors.orange),
                        title: const Text("Code Block"),
                        subtitle: const Text("```code```"),
                        onTap: () { Navigator.pop(context); _insertMarkdown('\n```\n', '\n```\n'); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.format_bold),
                        title: const Text("Bold"),
                        onTap: () { Navigator.pop(context); _insertMarkdown('**', '**'); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.format_italic),
                        title: const Text("Italic"),
                        onTap: () { Navigator.pop(context); _insertMarkdown('*', '*'); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.format_size),
                        title: const Text("Heading 3"),
                        onTap: () { Navigator.pop(context); _insertMarkdown('\n### ', ''); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.format_list_bulleted),
                        title: const Text("Bullet List"),
                        onTap: () { Navigator.pop(context); _insertMarkdown('\n- ', ''); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.check_box_outlined),
                        title: const Text("Task List"),
                        onTap: () { Navigator.pop(context); _insertMarkdown('\n- [ ] ', ''); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.format_quote),
                        title: const Text("Blockquote"),
                        onTap: () { Navigator.pop(context); _insertMarkdown('\n> ', ''); },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveNote() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and body cannot be empty')));
      return;
    }

    if (_isEditing) {
      await DatabaseHelper.updateNote(widget.existingNote!['id'], _titleController.text, _bodyController.text, folderId: widget.existingNote!['folder_id']);
    } else {
      await DatabaseHelper.saveNoteToLocalDevice(title: _titleController.text, body: _bodyController.text, folderId: widget.folderId);
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(hintText: "Title", border: InputBorder.none),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(hintText: "Start typing in Markdown...", border: InputBorder.none),
                ),
              ),
            ),
            // 👇 The Bottom Toolbar with Command Palette Button 👇
            Container(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_command_key, color: Colors.blue), 
                    onPressed: () => _showCommandPalette(context), 
                    tooltip: 'Command Palette'
                  ),
                  Container(width: 1, height: 24, color: Colors.grey), // Separator
                  IconButton(icon: const Icon(Icons.format_bold), onPressed: () => _insertMarkdown('**', '**'), tooltip: 'Bold'),
                  IconButton(icon: const Icon(Icons.format_italic), onPressed: () => _insertMarkdown('*', '*'), tooltip: 'Italic'),
                  IconButton(icon: const Icon(Icons.format_size), onPressed: () => _insertMarkdown('### ', ''), tooltip: 'Heading'),
                  IconButton(icon: const Icon(Icons.format_quote), onPressed: () => _insertMarkdown('> ', ''), tooltip: 'Quote'),
                  IconButton(icon: const Icon(Icons.image), onPressed: _insertImage, tooltip: 'Insert Image'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}