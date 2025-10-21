import 'package:cloud_firestore/cloud_firestore.dart';

// UPDATE THIS:
//  - Used in login_screen.dart

// Used to get specific field value from collection in Firestore Firebase

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Init firebase
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Get specific field value === example use:
  // String user_name = getField(users, uid, name) === where users is collection, uid should be unique, name is field
  // example output: user_name == Vonh Villaruz === from users/IA3ZGIz1IyRCaxQEH3qfLxVC3L73(uid)/name   
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

  // Get specific document and all of its field === example use:
  // var user_data = getDocument(users, uid)
  // example use: String username = user_data.name;
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

  // For querying docs with specific conditions, used in searching filtering
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
