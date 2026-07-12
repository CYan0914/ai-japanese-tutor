/// Audio recording and playback service.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  /// Start recording. Returns the file path.
  Future<String> startRecording() async {
    final dir = Directory.systemTemp;
    final path = '${dir.path}/sakura_input_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    return path;
  }

  /// Stop recording and return the audio bytes.
  Future<Uint8List?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    return File(path).readAsBytes();
  }

  /// Play audio from a URL or data URI.
  /// Data URIs (data:audio/mp3;base64,...) are NOT supported by just_audio's
  /// platform players, so we decode them to a temp file first.
  Future<void> playUrl(String url) async {
    await _player.stop();
    if (_isDataUri(url)) {
      final filePath = await _dataUriToFile(url);
      await _player.setFilePath(filePath);
    } else {
      await _player.setUrl(url);
    }
    await _player.play();
  }

  /// Play audio from file path.
  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.setFilePath(path);
    await _player.play();
  }

  // ── data URI helpers ──

  static bool _isDataUri(String url) => url.startsWith('data:');

  /// Decode a data URI to a temp file. Returns the file path.
  static Future<String> _dataUriToFile(String dataUri) async {
    // Parse: data:audio/mp3;base64,<data>
    final commaIdx = dataUri.indexOf(',');
    if (commaIdx == -1) throw Exception('Invalid data URI');
    final header = dataUri.substring(0, commaIdx);
    final b64 = dataUri.substring(commaIdx + 1);
    final isBase64 = header.contains(';base64');

    final bytes = isBase64 ? base64Decode(b64) : utf8.encode(b64);

    // Determine extension from MIME type
    String ext = '.mp3';
    if (header.contains('audio/wav') || header.contains('audio/wave')) {
      ext = '.wav';
    } else if (header.contains('audio/mpeg') || header.contains('audio/mp3')) {
      ext = '.mp3';
    }

    final dir = Directory.systemTemp;
    final path = '${dir.path}/sakura_tts_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  /// Check and request microphone permission.
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
