import 'dart:io';
import 'package:flutter/services.dart';

class FileExporter {
  static Future<String?> exportFile(String filename, String content) async {
    try {
      final directory = Directory.current;
      final path = '${directory.path}/$filename';
      final file = File(path);
      await file.writeAsString(content);
      return path;
    } catch (e) {
      Clipboard.setData(ClipboardData(text: content));
      throw Exception(e.toString());
    }
  }
}
