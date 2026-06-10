import 'package:flutter_tts/flutter_tts.dart';

class SpeechSynthesizer {
  final FlutterTts _flutterTts = FlutterTts();

  SpeechSynthesizer() {
    _initTts();
  }

  void _initTts() async {
    // Intentar configurar a español de España, si falla usar español de México o por defecto
    bool isLanguageAvailable = await _flutterTts.isLanguageAvailable("es-ES");
    if (isLanguageAvailable) {
      await _flutterTts.setLanguage("es-ES");
    } else {
      await _flutterTts.setLanguage("es-MX");
    }
    
    // Velocidad de habla natural y clara durante el entrenamiento (0.55 es un buen ritmo para TTS en Flutter)
    await _flutterTts.setSpeechRate(0.55);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void speak(String text) async {
    // Detener cualquier voz en curso para reproducir la nueva de forma inmediata
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void dispose() {
    _flutterTts.stop();
  }
}
