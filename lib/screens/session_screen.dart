// Màn hình phiên họp (hiển thị phụ đề)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:globe_cast/services/service_locator.dart';
import 'package:globe_cast/services/speech_to_text_services.dart';
import 'package:googleapis/connectors/v1.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SessionScreen extends StatefulWidget {
  final String sessionId;

  const SessionScreen({super.key, required this.sessionId});

  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _speechService = getIt<SpeechToTextService>();

  @override
  void initState() {
    super.initState();
    _startRecognition();
  }

  Future<void> _startRecognition() async {
    await _speechService.startRecognition(
        sessionId: widget.sessionId,
        isOnline: false); //switch in app
    // no need to define language, auto get device's language

    //Listen stream to update transcript
    _speechService.transcriptStream.listen((transcript){
      Provider.of<TranscriptProvider>(context, listen: false).addTranscript(transcript);
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: Consumer<TranscriptProvider>(
        builder: (context, provider, child){
          return ListView.builder(
            itemCount: provider.transcripts.length,
            itemBuilder: (context, index){
              final transcript = provider.transcripts[index];
              return ListTile(
                title: Text(transcript.text),
                subtitle: Text(transcript.timestamp.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
