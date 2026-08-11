import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Build-time: kısa, retro-tarz ses efektlerini saf Dart ile sentezler
/// (sinüs/kare/üçgen dalga + lineer attack/decay zarfı) ve
/// `assets/audio/sfx/`'e WAV olarak yazar. Harici ses dosyası/lisans
/// gerekmiyor — oyunun "tamamen offline" felsefesiyle uyumlu.
///
/// Kullanım: dart run scripts/generate_sfx.dart
const int kSampleRate = 44100;

void main() {
  final outDir = Directory('assets/audio/sfx');
  outDir.createSync(recursive: true);

  final sounds = <String, List<int>>{
    'tap.wav': _tap(),
    'success.wav': _success(),
    'error.wav': _error(),
    'level_clear.wav': _levelClear(),
    'combo.wav': _combo(),
    'purchase.wav': _purchase(),
  };

  for (final entry in sounds.entries) {
    final bytes = _buildWav(entry.value, sampleRate: kSampleRate);
    final file = File('${outDir.path}/${entry.key}');
    file.writeAsBytesSync(bytes);
    stdout.writeln('Yazıldı: ${file.path} (${bytes.length} bayt)');
  }
}

// --- Ses tarifleri -----------------------------------------------------

List<int> _tap() => _tone(freq: 880, durationMs: 55, amplitude: 0.45);

List<int> _success() => [
      ..._tone(freq: 660, durationMs: 80, amplitude: 0.4),
      ..._tone(freq: 990, durationMs: 130, amplitude: 0.45),
    ];

List<int> _error() => [
      ..._tone(
        freq: 220,
        durationMs: 110,
        amplitude: 0.4,
        wave: _Wave.square,
      ),
      ..._tone(
        freq: 165,
        durationMs: 140,
        amplitude: 0.35,
        wave: _Wave.square,
      ),
    ];

List<int> _levelClear() => [
      ..._tone(freq: 523.25, durationMs: 90, amplitude: 0.4),
      ..._tone(freq: 659.25, durationMs: 90, amplitude: 0.42),
      ..._tone(freq: 784.00, durationMs: 90, amplitude: 0.44),
      ..._tone(freq: 1046.50, durationMs: 180, amplitude: 0.5),
    ];

/// Tek nota — runtime'da SoundController bunu `setPlaybackRate` ile
/// perdeyi kaydırarak çalar (streak arttıkça daha tiz), ayrı dosyaya
/// gerek kalmaz.
List<int> _combo() => _tone(
      freq: 740,
      durationMs: 90,
      amplitude: 0.45,
      wave: _Wave.triangle,
    );

List<int> _purchase() => [
      ..._tone(freq: 988, durationMs: 45, amplitude: 0.4),
      ..._tone(freq: 1319, durationMs: 70, amplitude: 0.45),
    ];

// --- Sentez yardımcıları -------------------------------------------------

enum _Wave { sine, square, triangle }

double _sampleWave(_Wave wave, double phase) {
  switch (wave) {
    case _Wave.square:
      return phase < 0.5 ? 1.0 : -1.0;
    case _Wave.triangle:
      return phase < 0.5 ? (4 * phase - 1) : (3 - 4 * phase);
    case _Wave.sine:
      return sin(2 * pi * phase);
  }
}

/// Tek bir ton üretir; tık/çıtırtı olmasın diye lineer attack/decay zarfı
/// uygular.
List<int> _tone({
  required double freq,
  required double durationMs,
  double amplitude = 0.5,
  _Wave wave = _Wave.sine,
  double attackMs = 4,
  double decayMs = 18,
}) {
  final n = (kSampleRate * durationMs / 1000).round();
  final attackN = (kSampleRate * attackMs / 1000).round().clamp(1, n);
  final decayN = (kSampleRate * decayMs / 1000).round().clamp(1, n);
  final samples = <int>[];
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    phase += freq / kSampleRate;
    if (phase >= 1.0) phase -= 1.0;
    var env = 1.0;
    if (i < attackN) {
      env = i / attackN;
    } else if (i > n - decayN) {
      env = (n - i) / decayN;
    }
    final s = _sampleWave(wave, phase) * amplitude * env;
    samples.add((s * 32767).round().clamp(-32768, 32767));
  }
  return samples;
}

/// 16-bit PCM mono WAV (RIFF/WAVE) — harici paket gerekmeden elle yazılır.
Uint8List _buildWav(List<int> samples, {required int sampleRate}) {
  const bitsPerSample = 16;
  const numChannels = 1;
  final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  final blockAlign = numChannels * bitsPerSample ~/ 8;
  final dataSize = samples.length * 2;
  final buffer = BytesBuilder();

  void writeString(String s) => buffer.add(s.codeUnits);
  void writeUint32(int v) => buffer.add([
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ]);
  void writeUint16(int v) => buffer.add([v & 0xff, (v >> 8) & 0xff]);

  writeString('RIFF');
  writeUint32(36 + dataSize);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(numChannels);
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(blockAlign);
  writeUint16(bitsPerSample);
  writeString('data');
  writeUint32(dataSize);
  for (final raw in samples) {
    final v = raw.clamp(-32768, 32767);
    buffer.add([v & 0xff, (v >> 8) & 0xff]);
  }
  return buffer.toBytes();
}
