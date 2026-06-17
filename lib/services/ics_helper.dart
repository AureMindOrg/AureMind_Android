import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class IcsHelper {
  // Formats Dart DateTime to the strict iCalendar standard (e.g., 20260618T100000Z)
  static String _formatToIcsDate(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}00Z";
  }

  // Shares the generated string as a physical .ics file
  static Future<void> _shareFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported from AureMind');
  }

  // --- EXPORT EVENTS ---
  static Future<void> exportEvents(List<Map<String, dynamic>> events, String folderName) async {
    StringBuffer sb = StringBuffer();
    sb.writeln("BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//AureMind//Offline//EN");

    for (var ev in events) {
      DateTime dt = DateTime.parse(ev['event_date']).toUtc();
      sb.writeln("BEGIN:VEVENT");
      sb.writeln("SUMMARY:${ev['title']}");
      if (ev['description'] != null && ev['description'].toString().isNotEmpty) {
        sb.writeln("DESCRIPTION:${ev['description'].replaceAll('\n', '\\n')}");
      }
      sb.writeln("DTSTART:${_formatToIcsDate(dt)}");
      sb.writeln("DTEND:${_formatToIcsDate(dt.add(const Duration(hours: 1)))}");
      sb.writeln("END:VEVENT");
    }

    sb.writeln("END:VCALENDAR");
    await _shareFile(sb.toString(), "Events_$folderName.ics");
  }

  // --- EXPORT TIMETABLE ---
  // This automatically expands the weekly schedule into distinct daily calendar events!
  static Future<void> exportTimetable(Map<String, dynamic> timetable, List<Map<String, dynamic>> entries) async {
    StringBuffer sb = StringBuffer();
    sb.writeln("BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//AureMind//Offline//EN");

    DateTime start = DateTime.parse(timetable['start_date']);
    DateTime end = DateTime.parse(timetable['end_date']);

    for (DateTime d = start; d.isBefore(end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      int weekday = d.weekday;
      var dailyClasses = entries.where((e) => e['day_of_week'] == weekday).toList();
      
      for (var c in dailyClasses) {
        List<String> stParts = c['start_time'].toString().split(':');
        List<String> etParts = c['end_time'].toString().split(':');
        
        DateTime classStart = DateTime(d.year, d.month, d.day, int.parse(stParts[0]), int.parse(stParts[1])).toUtc();
        DateTime classEnd = DateTime(d.year, d.month, d.day, int.parse(etParts[0]), int.parse(etParts[1])).toUtc();

        sb.writeln("BEGIN:VEVENT");
        sb.writeln("SUMMARY:${c['subject']} (Class)");
        sb.writeln("DTSTART:${_formatToIcsDate(classStart)}");
        sb.writeln("DTEND:${_formatToIcsDate(classEnd)}");
        sb.writeln("END:VEVENT");
      }
    }

    sb.writeln("END:VCALENDAR");
    String safeTitle = timetable['title'].toString().replaceAll(' ', '_');
    await _shareFile(sb.toString(), "Timetable_$safeTitle.ics");
  }

  // --- IMPORT ICS DATA ---
  static Future<List<Map<String, dynamic>>> parseIcsFile(String filePath) async {
    File file = File(filePath);
    String contents = await file.readAsString();
    List<String> lines = contents.split('\n');
    
    List<Map<String, dynamic>> parsedEvents = [];
    String? title, desc; DateTime? dt;

    for (String line in lines) {
      line = line.trim();
      if (line.startsWith("SUMMARY:")) title = line.substring(8);
      if (line.startsWith("DESCRIPTION:")) desc = line.substring(12).replaceAll('\\n', '\n');
      if (line.startsWith("DTSTART:")) {
        String dateStr = line.split(':').last.replaceAll('Z', '').replaceAll('T', ''); 
        if (dateStr.length >= 8) {
          int y = int.parse(dateStr.substring(0, 4));
          int m = int.parse(dateStr.substring(4, 6));
          int d = int.parse(dateStr.substring(6, 8));
          dt = DateTime(y, m, d);
        }
      }
      if (line == "END:VEVENT" && title != null && dt != null) {
        parsedEvents.add({'title': title, 'description': desc ?? 'Imported Event', 'event_date': dt});
        title = null; desc = null; dt = null;
      }
    }
    return parsedEvents;
  }
}