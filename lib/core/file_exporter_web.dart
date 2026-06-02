import 'dart:js' as js;
import 'package:flutter/services.dart';

class FileExporter {
  static Future<String?> exportFile(String filename, String content) async {
    try {
      js.context.callMethod('downloadFile', [filename, content]);
      return 'web';
    } catch (e) {
      Clipboard.setData(ClipboardData(text: content));
      throw Exception(e.toString());
    }
  }
}
