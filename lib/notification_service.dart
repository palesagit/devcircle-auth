//Handles Firebase Cloud Messaging 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> init(String uid) async {
    try {
      
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);

      _messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));
    } catch (e) {
      
      debugPrint('FCM setup skipped: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;
}
