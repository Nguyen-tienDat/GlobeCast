import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:globe_cast/services/firebase_services.dart';
import 'webrtc_services.dart';
import 'speech_to_text_services.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<FirebaseServices>(FirebaseServices());
  getIt.registerSingleton<SpeechToTextService>(SpeechToTextService());
}