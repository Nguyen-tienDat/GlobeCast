import 'package:get_it/get_it.dart';
import 'webrtc_services.dart';
import 'speech_to_text_services.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<WebRTCService>(WebRTCService());
  getIt.registerSingleton<SpeechToTextService>(SpeechToTextService());
}