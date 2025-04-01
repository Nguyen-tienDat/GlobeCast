import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/apis.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  String? _currentCallId;
  MediaStream? _localStream;
  String? get currentCallId => _currentCallId;

  final _configuration = {
    'iceServers': [
      {
        "urls": "turn:huyln.info:3478",
        "username": "huyln38",
        "credential": "huy123456789"
      }
    ],
    'sdpSemantics': 'unified-plan'
  };

  // Request and check camera/microphone permissions
  Future<bool> _handlePermissions() async {
    // Request permissions
    await Permission.camera.request();
    await Permission.microphone.request();

    // Check if permissions were granted
    bool cameras = await Permission.camera.isGranted;
    bool microphone = await Permission.microphone.isGranted;

    // Return true only if both permissions are granted
    return cameras && microphone;
  }

  // Create a new WebRTC peer connection
  Future<RTCPeerConnection> _createPeerConnection() async {
    // Create the peer connection with our configuration
    RTCPeerConnection pc = await createPeerConnection(_configuration);
    return pc;
  }

  //Request Camera from receiver
  Future<void> requestCamera() async{
    if(_currentCallId != null){
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(_currentCallId)
          .update({
        'camRequest.fromCaller': true,
      });
    }
  }

  //Enable Camera for Receiver
  Future<void> enableCamera() async{
    if(_localStream != null){
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = true;

      if(_currentCallId != null){
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(_currentCallId)
            .update({
          'camRequest.fromReceiver': true,
        });
      }
    }
  }

  // Initialize a call to another user
  Future<void> initiateCall(String receiverId, // ID of user being called
      MediaStream localStream, // Local video/audio stream
      RTCVideoRenderer localRenderer, // Widget to display local video
      RTCVideoRenderer remoteRenderer, {
        // Widget to display remote video
        required Function onCallAccepted, // Callback when call is accepted
        required Function onCallRejected, // Callback when call is rejected
        required Function onCallEnded, // Callback when call ends
        required Function(String) onError, // Callback for errors
      }) async {
    try {
      // First check permissions
      final bool hasPermissions = await _handlePermissions();
      if (!(await Permission.camera.isGranted) ||
          !(await Permission.microphone.isGranted)) {
        throw Exception('Camera and microphone permissions are required');
      }

      // Generate unique call ID using timestamp
      _currentCallId = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();

      // Create peer connection
      _peerConnection = await _createPeerConnection();
      print('[Caller] Peer connection created');

      // Add local video/audio tracks to the connection
      localStream.getTracks().forEach((track) {
        print('[Caller] Adding track: ${track.kind}');
        _peerConnection!.addTrack(track, localStream);
      });

      // Set up handler for incoming remote streams
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        print('[Caller] onTrack: ${event.streams.length} streams');
        if (event.streams.isNotEmpty) {
          // Display remote video when received
          remoteRenderer.srcObject = event.streams[0];
          print('[Caller] Remote stream set to renderer');
        } else {
          print('[Caller] No remote received');
        }
      };

      // Monitor connection state changes
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        print('[Caller] Connection state changed: $state');
      };

      // Monitor ICE connection state changes
      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        print('[Caller] ICE Connection state: $state');
      };

      // Set up handler for ICE candidates
      _peerConnection!.onIceCandidate = (candidate) async {
        print('[Caller] New ICE candidate: ${candidate.candidate}');
        // Store ICE candidate in Firebase
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(_currentCallId)
            .collection('callerCandidates')
            .add(candidate.toMap());
      };

      // Create offer to send to receiver
      RTCSessionDescription offer = await _peerConnection!
          .createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 1});

      // Set our local description
      await _peerConnection!.setLocalDescription(offer);
      print('[Caller] Local description set');

      // Send SDP offer
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(_currentCallId)
          .set({
        'callerId': Apis.me.id,
        'receiverId': receiverId,
        'offer': offer.toMap(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('[Caller] Offer stored in Firestore');

      // Listen for answer and status changes
      FirebaseFirestore.instance
          .collection('calls')
          .doc(_currentCallId)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        print('[Caller] Call status changed: ${data['status']}');

        // Handle different call states
        switch (data['status']) {
          case 'rejected':
            await endCall();
            onCallRejected();
            break;
          case 'ended':
            await endCall();
            onCallEnded();
            break;
          case 'accepted':
            if (data['answer'] != null) {
              // When we get the answer, set it as remote description
              final answer = RTCSessionDescription(
                data['answer']['sdp'],
                data['answer']['type'],
              );
              print('[Caller] Setting remote description from answer');
              await _peerConnection!.setRemoteDescription(answer);
              onCallAccepted();
            }
            break;
        }
      });

      // Listen for ICE candidates from receiver
      FirebaseFirestore.instance
          .collection('calls')
          .doc(_currentCallId)
          .collection('receiverCandidates')
          .snapshots()
          .listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            print('[Caller] Adding receiver ICE candidate');
            final candidateData = change.doc.data()!;
            final candidate = RTCIceCandidate(
              candidateData['candidate'],
              candidateData['sdpMid'],
              candidateData['sdpMLineIndex'],
            );
            await _peerConnection!.addCandidate(candidate);
          }
        }
      });
    } catch (e) {
      print('[Caller] Error in initiateCall: $e');
      await endCall();
      onError(e.toString());
    }
  }

  // Handle incoming call
  Future<void> handleIncomingCall(String callId, // ID of incoming call
      MediaStream localStream, // Local video/audio stream
      RTCVideoRenderer localRenderer, // Widget to display local video
      RTCVideoRenderer remoteRenderer, {
        // Widget to display remote video
        required Function(String) onError, // Callback for errors
        required Function onCamera, //Callback for camera request
      }) async {
    try {
      _currentCallId = callId;
      print('[Receiver] Handling incoming call: $callId');

      // Create peer connection
      _peerConnection = await _createPeerConnection();
      print('[Receiver] Peer connection created');

      // Add our local video/audio tracks
      localStream.getTracks().forEach((track) {
        print('[Caller] Adding track: ${track.kind}');
        _peerConnection!.addTrack(track, localStream);
      });

      // Set up handler for incoming remote streams
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        print('[Receiver] onTrack: ${event.streams.length} streams');
        if (event.streams.isNotEmpty) {
          // Display remote video when received
          remoteRenderer.srcObject = event.streams[0];
          print('[Receiver] Remote stream set to renderer');
        }
      };

      // Monitor connection states
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        print('[Receiver] Connection state changed: $state');
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        print('[Receiver] ICE Connection state: $state');
      };

      // Handle our ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
        try {
          print('[Receiver] New ICE candidate: ${candidate.candidate}');

          // Add ICE candidates to Firestore
          await FirebaseFirestore.instance
              .collection('calls')
              .doc(_currentCallId)
              .collection('receiverCandidates')
              .add(candidate.toMap());

          print('[Receiver] ICE candidate added to Firestore');
        } catch (e) {
          print('[Receiver] Error adding ICE candidate: $e');
        }
      };

      // Get the offer from Firebase
      final callDoc = await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .get();

      if (!callDoc.exists) {
        throw Exception('Call document not found');
      }

      // Set the caller's offer as our remote description
      final offerData = callDoc.data()!['offer'];
      final offer = RTCSessionDescription(
        offerData['sdp'],
        offerData['type'],
      );
      print('[Receiver] Setting remote description from offer');
      await _peerConnection!.setRemoteDescription(offer);

      // Create our answer
      RTCSessionDescription answer = await _peerConnection!
          .createAnswer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 1});
      print('[Receiver] Setting local description (answer)');
      await _peerConnection!.setLocalDescription(answer);

      // Store our answer in Firebase
      await FirebaseFirestore.instance.collection('calls').doc(callId).update({
        'answer': answer.toMap(),
        'status': 'accepted',
      });
      print('[Receiver] Answer stored in Firestore');

      //Listen for Camera request from caller
      FirebaseFirestore.instance
          .collection('calls')
          .doc(_currentCallId)
          .snapshots()
          .listen((snapshot){
        if(!snapshot.exists) return;

        final data = snapshot.data()!;
        if (data['camRequest'] != null && data['camRequest']['fromCaller'] == true){
          onCamera();
        }
      });

      // Listen for ICE candidates from caller
      FirebaseFirestore.instance
          .collection('calls')
          .doc(_currentCallId)
          .collection('callerCandidates')
          .snapshots()
          .listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            print('[Receiver] Adding caller ICE candidate');
            final candidateData = change.doc.data()!;
            final candidate = RTCIceCandidate(
              candidateData['candidate'],
              candidateData['sdpMid'],
              candidateData['sdpMLineIndex'],
            );
            await _peerConnection!.addCandidate(candidate);
          }
        }
      }
      );
    } catch (e) {
      print('[Receiver] Error in handleIncomingCall: $e');
      await endCall();
      onError(e.toString());
    }
  }

  // Handle call rejection
  Future<void> rejectCall(String callId) async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .update({'status': 'rejected'});
    } catch (e) {
      print('Error rejecting call: $e');
    }
  }

  // End an ongoing call
  Future<void> endCall() async {
    try {
      if (_currentCallId != null) {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(_currentCallId)
            .update({'status': 'ended'});
      }

      // Clean up WebRTC connection
      await _peerConnection?.close();
      _peerConnection = null;
      _currentCallId = null;
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  // Clean up resources
  void dispose() {
    endCall();
  }
}


