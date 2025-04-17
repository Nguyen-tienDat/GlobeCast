// Xử lí DB (Auth, Firestore)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng nhập ẩn danh (cho demo)
  Future<User?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Lấy user hiện tại
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Tạo một session mới
  Future<String> createSession(String sessionName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final sessionRef = await _firestore.collection('sessions').add({
      'name': sessionName,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return sessionRef.id;
  }

  // Lấy danh sách sessions
  Stream<QuerySnapshot> getSessions() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('sessions')
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Lấy transcripts của một session
  Stream<QuerySnapshot> getTranscripts(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('transcripts')
        .orderBy('timestamp')
        .snapshots();
  }

  // Xóa một session (bao gồm transcripts)
  Future<void> deleteSession(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Xóa tất cả transcripts của session
    final transcripts = await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('transcripts')
        .get();
    for (var doc in transcripts.docs) {
      await doc.reference.delete();
    }

    // Xóa session
    await _firestore.collection('sessions').doc(sessionId).delete();
  }
}