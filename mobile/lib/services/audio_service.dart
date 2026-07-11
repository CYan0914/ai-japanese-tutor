/// Audio recording and playback service.
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

  /// Play audio from a URL (or base64 data URI).
  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.setUrl(url);
    await _player.play();
  }

  /// Play audio from file path.
  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.setFilePath(path);
    await _player.play();
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
