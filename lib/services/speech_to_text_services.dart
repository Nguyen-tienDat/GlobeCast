// Xử lí Speech-to-Text ( GG ML KIT)
import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:googleapis/androidenterprise/v1.dart';
import 'package:googleapis/speech/v1.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {
  //instance of GG ML Kit Stt
  final SpeechToText _speechToText = SpeechToText();

  //instance of Flutter sound to record offline
  final FlutterSoundRecorder _flutterSoundRecorder = FlutterSoundRecorder();

  //Stream to realize realtime sound
  final StreamController<Transcript> _transcriptController =
      StreamController<Transcript>.broadcast();

  //Firestore to save transcript
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //control record actions
  bool _isRecording = false;
  bool _isInitialized = false;

  //ID to save transcript
  String? _sessionId;

  //Stream to listen record result
  Stream<Transcript> get transcriptStream => _transcriptController.stream;

  //initialize
  Future<void> init() async {
    if (_isInitialized) return;

    //Micro Permission
    var status = await mic_handle.Permission.microphone.request();
    if (status != mic_handle.PermissionStatus.granted) {
      throw Exception('Micro permission not granted');
    }

    //Flutter sound
    await _flutterSoundRecorder.openRecorder();
    _isInitialized = true;
  }

  //Get device's language
  String getDeviceLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    String languageCode = locale.toString();
    if (languageCode.contains('_')) {
      final parts = languageCode.split('_');
      languageCode = '${parts[0]}-${parts[1]}';
    }
    //Check the language is available, if not, set En-Us as Default
    final supportedLanguages = [
      'vi-VN',
      'en-US',
      'es-ES',
      'fr_FR',
    ];
    return supportedLanguages.contains(languageCode) ? languageCode : 'en-US';
  }

  //Translate
  Future<void> startRecognition({
    required String sessionId,
    required bool isOnline,
    String? language,
  }) async {
    if (!_isInitialized) await init();
    if (_isRecording) return;
    _sessionId = sessionId;
    _isRecording = true;

    final selectedLanguage = language ?? getDeviceLanguage();

    try {
      final avaiable = await _speechToText.initialize();
      if (!avaiable) {
        throw Exception('SpeechToText initialize failed');
      }
      if (isOnline) {
        await _startMicroRecognition(selectedLanguage);
      } else {
        await _startMicroRecognition(selectedLanguage);
      }
    } catch (e) {
      _isRecording = false;
      rethrow;
    }
  }

  Future<void> stopRecognition() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _flutterSoundRecorder.stopRecorder();
    await _speechToText.stop();
    _transcriptController.close();
  }

  //Handle record from micro and translate
  Future<void> _startMicroRecognition(String language) async {
    await _flutterSoundRecorder.startRecorder(
      codec: Codec.pcm16,
      sampleRate: 16000,
    );

    //Start to listen voice
    _speechToText.listen(
      onResult: (result) {
        if (!_isRecording) return;

        if (result.recognizedWords.isNotEmpty) {
          final trnascript = Transcript(
            text: result.recognizedWords,
            timestamp: DateTime.now(),
            language: language,
          );
          //Output data through stream to UI update
          _transcriptController.add(transcript);
          //Save transcript to Firestore
          _saveTranscript(trnascript);
        }
      },
      localeId: language,
      partialResults: true,
    );

    //Listen voice data from micro (test status)
    _flutterSoundRecorder.onProgress!.listen((event) {
      if (!_isRecording) {
        _speechToText.stop();
      }
    });
  }

  //Save transcript to Firestore
  Future<void> _saveTranscript(Transcript transcript) async {
    if (_sessionId == null) return;

    await _firestore
        .collection('sessions')
        .doc(_sessionId)
        .collection('transcripts')
        .add({
      'text': transcript.text,
      'timestamp': transcript.timestamp.toIso8601String(),
      'language': transcript.language,
    });
  }

//Dispose
  void dispose() {
    stopRecognition();
    _flutterSoundRecorder.closeRecorder();
    _speechToText.stop();
    _transcriptController.close();
  }
}
