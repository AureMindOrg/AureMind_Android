import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/theme_provider.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    Color tempColor = themeProvider.customColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick App Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: themeProvider.customColor,
            onColorChanged: (color) => tempColor = color,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              themeProvider.setCustomColor(tempColor);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'Settings'),
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text("Appearance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Theme Mode'),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      underline: const SizedBox(),
                      onChanged: (ThemeMode? newMode) {
                        if (newMode != null) themeProvider.setThemeMode(newMode);
                      },
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System Default')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.color_lens),
                    title: const Text('Material You'),
                    subtitle: const Text('Sync colors with your wallpaper'),
                    value: themeProvider.useDynamicColor,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (bool value) => themeProvider.setUseDynamicColor(value),
                  ),
                  if (!themeProvider.useDynamicColor) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.format_color_fill),
                      title: const Text('Custom Accent Color'),
                      trailing: CircleAvatar(backgroundColor: themeProvider.customColor, radius: 14),
                      onTap: () => _showColorPicker(context, themeProvider),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}