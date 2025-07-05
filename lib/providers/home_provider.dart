import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_demo/constants/firestore_constants.dart';

/// Provider for home screen functionalities:
/// updating user data and streaming users with optional search.
class HomeProvider {
  final FirebaseFirestore firebaseFirestore;

  HomeProvider({required this.firebaseFirestore});

  /// Updates Firestore document with given data.
  Future<void> updateDataFirestore(String collectionPath, String path,
      Map<String, String> dataNeedUpdate) async {
    try {
      await firebaseFirestore
          .collection(collectionPath)
          .doc(path)
          .update(dataNeedUpdate);
    } catch (e) {
      print('Error updating Firestore data: $e');
      rethrow;
    }
  }

  /// Returns a stream of documents with optional nickname search.
  Stream<QuerySnapshot> getStreamFireStore(
      String pathCollection, int limit, String? textSearch) {
    if (textSearch?.isNotEmpty == true) {
      return firebaseFirestore
          .collection(pathCollection)
          .limit(limit)
          .where(FirestoreConstants.nickname, isEqualTo: textSearch)
          .snapshots();
    }
    return firebaseFirestore
        .collection(pathCollection)
        .limit(limit)
        .snapshots();
  }
}
