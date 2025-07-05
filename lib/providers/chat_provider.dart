import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_demo/constants/firestore_constants.dart';
import 'package:flutter_chat_demo/models/message_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for chat-related functionality:
/// sending and streaming text messages only.
class ChatProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;

  ChatProvider({
    required this.firebaseFirestore,
    required this.prefs,
  });

  /// Updates Firestore document with provided data.
  Future<void> updateDataFirestore(String collectionPath, String docPath,
      Map<String, dynamic> dataNeedUpdate) async {
    try {
      await firebaseFirestore
          .collection(collectionPath)
          .doc(docPath)
          .update(dataNeedUpdate);
    } catch (e) {
      print('Error updating Firestore data: $e');
      rethrow;
    }
  }

  /// Returns a stream of chat messages from Firestore with limit.
  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    return firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Sends a new text message to Firestore in a transaction.
  Future<void> sendMessage(String content, int type, String groupChatId,
      String currentUserId, String peerId) async {
    final documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    final messageChat = MessageChat(
      idFrom: currentUserId,
      idTo: peerId,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type, // you can use 0 for text messages if you want
    );

    try {
      await firebaseFirestore.runTransaction((transaction) async {
        transaction.set(documentReference, messageChat.toJson());
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
