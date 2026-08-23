import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Writes CSV content to a fixed, well-known location on disk.
///
/// This is intentionally lightweight and not "production ready" — the reports
/// are only exported a handful of times by an administrator, so a deterministic
/// path is preferred over a native Save dialog.
///
/// Resolution order for the directory:
///   1. `getDownloadsDirectory()` — the obvious home for an export on desktop
///      (Windows/macOS/Linux).
///   2. `getApplicationDocumentsDirectory()` — fallback for platforms where
///      there is no Downloads folder (or in tests).
///
/// Returns the absolute path of the file that was written, or `null` if the
/// write failed.
class CsvExportService {
  CsvExportService();

  /// Writes [content] to a file named `quickwork_admin_reports_<timestamp>.csv`.
  ///
  /// [overridesHandler] lets tests inject a fake path provider so no real file
  /// is touched. It defaults to the platform implementation.
  Future<String?> export({
    required String content,
    Future<Directory?> Function()? getDir,
  }) async {
    try {
      final dir = await (getDir ?? _defaultDirectory)();
      if (dir == null) return null;

      final stamp = _timestamp();
      final file = File('${dir.path}${Platform.pathSeparator}'
          'quickwork_admin_reports_$stamp.csv');
      await file.writeAsString(content);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<Directory?> _defaultDirectory() async {
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      /* not available on this platform */
    }
    if (dir != null) return dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      /* ignore */
    }
    return dir;
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}'
        '${three(now.millisecond)}';
  }
}
