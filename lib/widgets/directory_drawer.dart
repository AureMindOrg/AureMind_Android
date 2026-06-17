import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/database_helper.dart';
import '../screens/notes_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/events_screen.dart';

class DirectoryDrawer extends StatefulWidget {
  final String type; 
  final int? currentFolderId;

  const DirectoryDrawer({super.key, required this.type, this.currentFolderId});

  @override
  State<DirectoryDrawer> createState() => _DirectoryDrawerState();
}

class _DirectoryDrawerState extends State<DirectoryDrawer> {
  List<Map<String, dynamic>> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await DatabaseHelper.fetchFolders(widget.type);
    setState(() { _folders = folders; });
  }

  void _showAddFolderDialog() {
    final controller = TextEditingController();
    Color selectedColor = Colors.amber;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("New ${widget.type[0].toUpperCase()}${widget.type.substring(1)} Folder"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Folder Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text("Select Color:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              BlockPicker(
                pickerColor: selectedColor,
                onColorChanged: (c) => setStateDialog(() => selectedColor = c),
                layoutBuilder: (context, colors, child) => GridView.count(
                  crossAxisCount: 5, 
                  crossAxisSpacing: 5, 
                  mainAxisSpacing: 5, 
                  shrinkWrap: true,
                  children: colors.map((c) => child(c)).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await DatabaseHelper.saveFolder(controller.text, widget.type, color: selectedColor.value);
                  if (context.mounted) Navigator.pop(context);
                  _loadFolders();
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFolder(int? folderId, String? folderName) {
    Navigator.pop(context); 
    Widget screen;     
    
    if (widget.type == 'note') {
      screen = NotesScreen(folderId: folderId, folderName: folderName);
    } else if (widget.type == 'task') {
      screen = TasksScreen(folderId: folderId, folderName: folderName); 
    } else {
      screen = EventsScreen(folderId: folderId, folderName: folderName);
    }     
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _deleteFolder(int id) async {
    await DatabaseHelper.deleteFolder(id);
    _loadFolders();
    if (widget.currentFolderId == id && mounted) _navigateToFolder(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("EXPLORER", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder, size: 20),
                    onPressed: _showAddFolderDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.folder_special, color: Colors.blue),
              title: const Text("Root Directory"),
              selected: widget.currentFolderId == null,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              onTap: () => _navigateToFolder(null, null),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  final folder = _folders[index];
                  final isSelected = widget.currentFolderId == folder['id'];
                  
                  // Restore custom folder color from database
                  Color folderColor = Colors.amber;
                  if (folder['color'] != null) {
                    folderColor = Color(int.parse(folder['color'].toString()));
                  }

                  return ListTile(
                    leading: Icon(Icons.folder, color: folderColor),
                    title: Text(folder['name']),
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    onTap: () => _navigateToFolder(folder['id'], folder['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () => _deleteFolder(folder['id']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}