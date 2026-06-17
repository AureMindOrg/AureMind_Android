import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/app_drawer.dart';
import '../widgets/directory_drawer.dart';
import 'note_form_screen.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  final int? folderId;
  final String? folderName;

  const NotesScreen({super.key, this.folderId, this.folderName});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  Set<int> _selectedIds = {};

  void _refreshNotes() {
    setState(() { _selectedIds.clear(); });
  }

  void _deleteSelected() async {
    await DatabaseHelper.deleteNotes(_selectedIds.toList());
    _refreshNotes();
  }

  void _toggleSelection(int id) {
    setState(() {
      _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.folderName != null ? '📁 ${widget.folderName}' : 'My Notes';
    if (_selectedIds.isNotEmpty) displayTitle = '${_selectedIds.length} Selected';

    return Scaffold(
      // 👇 Left Sidebar: VS Code Directory 👇
      drawer: DirectoryDrawer(type: 'note', currentFolderId: widget.folderId),
      // 👇 Right Sidebar: Main Menu 👇
      endDrawer: const AppDrawer(currentRoute: 'Notes'), 
      
      appBar: AppBar(
        title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelected),
          // Add a hamburger menu button to the right side manually since we moved the AppDrawer
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          // 👇 Fetches ONLY notes inside the selected folder 👇
          future: DatabaseHelper.fetchNotes(folderId: widget.folderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(widget.folderId == null ? "No notes found. Create one!" : "This folder is empty."));
            }

            final notes = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 85),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final hasAttachment = note['attachment_path'] != null && note['attachment_path'].toString().isNotEmpty;
                final isSelected = _selectedIds.contains(note['id']);

                return GestureDetector(
                  onLongPress: () => _toggleSelection(note['id']),
                  onTap: () {
                    if (_selectedIds.isNotEmpty) {
                      _toggleSelection(note['id']);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)))
                          .then((_) => _refreshNotes());
                    }
                  },
                  child: Card(
                    elevation: 3,
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(note['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20)
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(note['decrypted_content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.3), maxLines: 5, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          if (hasAttachment) ...[
                            const Divider(),
                            const Row(
                              children: [
                                Icon(Icons.attach_file, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text("Attached", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: _selectedIds.isEmpty ? FloatingActionButton(
        onPressed: () async {
          // When creating a note, pass the current folder ID so it saves inside this specific folder!
          await Navigator.push(context, MaterialPageRoute(builder: (context) => NoteFormScreen(folderId: widget.folderId)));
          _refreshNotes();
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}