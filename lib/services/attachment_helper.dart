import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AttachmentResult {
  final String localPath;
  final String originalName;

  AttachmentResult({required this.localPath, required this.originalName});
}

class AttachmentHelper {
  static Future<AttachmentResult?> pickAndSaveAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String originalPath = result.files.single.path!;
        String originalName = result.files.single.name;

        Directory appDocDir = await getApplicationDocumentsDirectory();
        Directory attachmentsDir = Directory('${appDocDir.path}/attachments');
        if (!await attachmentsDir.exists()) {
          await attachmentsDir.create(recursive: true);
        }

        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String targetFileName = '${timestamp}_$originalName';
        String targetPath = path.join(attachmentsDir.path, targetFileName);

        File originalFile = File(originalPath);
        await originalFile.copy(targetPath);

        return AttachmentResult(
          localPath: targetPath,
          originalName: originalName,
        );
      }
    } catch (e) {
      // Safely ignore or log errors
    }
    return null;
  }
}