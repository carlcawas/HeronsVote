import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  Future<dynamic> getField(String collection, String docId, String field) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return doc.get(field);
      } else {
        throw Exception('Document not found');
      }
    } catch (e) {
      print('Error getting field: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> queryDocuments(
      String collection, String field, dynamic value) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error querying documents: $e');
      return [];
    }
  }
}
