import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'note_form_screen.dart';
import '../services/database_helper.dart'; 

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

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    String cleanContent = currentNote['decrypted_content']
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('### ', '')
        .replaceAll('> ', '');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(currentNote['title'], style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text(cleanContent, style: const pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(), 
      filename: '${currentNote['title']}.pdf'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Read Mode"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export as PDF',
            onPressed: _exportToPDF,
          ),
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
              const Divider(),
              MarkdownBody(
                data: currentNote['decrypted_content'] ?? '',
                selectable: true,
                inlineSyntaxes: [WikiLinkSyntax()],
                builders: {'wiki_link': WikiLinkBuilder(context)},
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 16, height: 1.5),
                  h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  blockquote: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4)),
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                ),
                imageBuilder: (uri, title, alt) {
                  if (uri.scheme == 'file' || uri.path.startsWith('/')) {
                    File imgFile = File(uri.path);
                    if (imgFile.existsSync()) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(imgFile),
                        ),
                      );
                    }
                  }
                  return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- OBSIDIAN SYNTAX LOGIC ---

class WikiLinkSyntax extends md.InlineSyntax {
  WikiLinkSyntax() : super(r'\[\[(.*?)\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final noteTitle = match[1]!;
    final el = md.Element.text('wiki_link', noteTitle);
    el.attributes['href'] = noteTitle; 
    parser.addNode(el);
    return true;
  }
}

class WikiLinkBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  WikiLinkBuilder(this.context);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final noteTitle = element.attributes['href'] ?? '';
    return GestureDetector(
      onTap: () async {
        final notes = await DatabaseHelper.fetchNotes();
        final targetNote = notes.firstWhere(
          (n) => n['title'].toString().toLowerCase() == noteTitle.toLowerCase(), 
          orElse: () => <String, dynamic>{}
        );

        if (targetNote.isNotEmpty && context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(note: targetNote)));
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Note '$noteTitle' not found.")));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2), 
          borderRadius: BorderRadius.circular(4)
        ),
        child: Text(noteTitle, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}