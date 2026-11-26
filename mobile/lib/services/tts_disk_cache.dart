/// On-disk cache for TTS audio URLs (P1).
///
/// The backend now serves cacheable https audio (GET /audio/{key}.mp3,
/// Cache-Control: immutable). just_audio streams from network every play;
/// this layer downloads once to the temp dir keyed by URL hash and replays
/// the file afterwards — repeat taps on the same phrase cost zero bytes.
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TtsDiskCache {
  static String _fileNameFor(String url) {
    final digest = sha256.convert(utf8.encode(url)).toString().substring(0, 32);
    final ext = url.contains('.wav') ? '.wav' : '.mp3';
    return 'sakura_tts_cache_$digest$ext';
  }

  static Future<File> _fileFor(String url) async {
    final dir = Directory.systemTemp;
    return File('${dir.path}/${_fileNameFor(url)}');
  }

  /// Return a local file for [url], downloading once on miss.
  /// Throws on download failure so callers can fall back to streaming.
  static Future<File> resolve(
    String url, {
    Map<String, String>? headers,
  }) async {
    final file = await _fileFor(url);
    if (await file.exists()) {
      final len = await file.length();
      if (len > 0) return file;
      try {
        await file.delete();
      } catch (_) {}
    }
    final resp = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw Exception('TTS download failed: ${resp.statusCode}');
    }
    await file.writeAsBytes(resp.bodyBytes);
    return file;
  }

  /// Best-effort prune: drop cached files older than [maxAge].
  static Future<void> prune({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final dir = Directory.systemTemp;
      final cutoff = DateTime.now().subtract(maxAge);
      await for (final ent in dir.list()) {
        final name = ent.path.split(Platform.pathSeparator).last;
        if (!name.startsWith('sakura_tts_cache_')) continue;
        try {
          final stat = await ent.stat();
          if (stat.modified.isBefore(cutoff)) await ent.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }
}
