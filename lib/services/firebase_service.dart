import 'package:cloud_firestore/cloud_firestore.dart';

/// UPDATE THIS:
///  - Used in login_screen.dart
///  - Used in home.dart, fetching data from `colleges`, `elections`, and `proposals`
/// ----------------------------------

/// Used to get specific field value from collection in Firestore Firebase
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Init firebase
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// Get specific field value === example use:
  /// String user_name = getField(users, uid, name)
  /// === where users is collection, uid should be unique, name is field
  Future<dynamic> getField(String collection, String docId, String field) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collection).doc(docId).get();
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

  /// Get specific document and all of its fields === example use:
  /// var user_data = getDocument(users, uid)
  /// example use: String username = user_data.name;
  Future<Map<String, dynamic>?> getDocument(
      String collection, String docId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collection).doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  /// For querying docs with specific conditions, used in searching/filtering
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

  /// Get all colleges from the `colleges` collection
  Future<List<Map<String, dynamic>>> getAllColleges() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('colleges').get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error fetching colleges: $e');
      return [];
    }
  }

  /// Gets a live stream of the user's document.
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Gets a live stream of the active college election for the user.
  Stream<QuerySnapshot> getActiveCollegeElectionStream(String collegeId) {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'college')
        .where('college_id', isEqualTo: collegeId)
        .where('ongoing', isEqualTo: true)
        .limit(1)
        .snapshots();
  }

  /// Gets a live stream of the active university-wide election.
  Stream<QuerySnapshot> getActiveUniversityElectionStream() {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'university')
        .where('ongoing', isEqualTo: true)
        .limit(1)
        .snapshots();
  }

  /// Gets a live stream of the active university-wide proposal.
  Stream<QuerySnapshot> getActiveUniversityProposalStream() {
    return _firestore
        .collection('proposals')
        .where('ongoing', isEqualTo: true)
        .limit(1)
        .snapshots();
  }

  /// Gets a stream of recently ended college elections (ended within the last 7 days).
  Stream<QuerySnapshot> getRecentlyEndedCollegeElection(String collegeId) {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'college')
        .where('college_id', isEqualTo: collegeId)
        .where('ongoing', isEqualTo: false) // Check for ended elections
        .orderBy('end', descending: true) // Get the most recent one
        .limit(1)
        .snapshots();
  }

  /// Gets a stream of recently ended university elections (ended within the last 7 days).
  Stream<QuerySnapshot> getRecentlyEndedUniversityElection() {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'university')
        .where('ongoing', isEqualTo: false) // Check for ended elections
        .orderBy('end', descending: true) // Get the most recent one
        .limit(1)
        .snapshots();
  }
  
  /// Gets recently ended university proposals (ended within the last 7 days).
  Stream<QuerySnapshot> getRecentlyEndedUniversityProposal() {
    return _firestore
        .collection('proposals')
        .where('ongoing', isEqualTo: false)
        .orderBy('end', descending: true)
        .limit(1)
        .snapshots();
  }

  /// Get a live stream of all slates for a specific election
  Stream<QuerySnapshot> getSlatesStream(String electionId) {
    return _firestore
        .collection('elections')
        .doc(electionId)
        .collection('slates')
        .orderBy('name')
        .snapshots();
  }

  /// Get a live stream of current officials for a specific college
  Stream<QuerySnapshot> getCurrentOfficialsStream(String collegeId) {
    return _firestore
        .collection('colleges')
        .doc(collegeId)
        .collection('officials')
        .orderBy('rank', descending: false) 
        .snapshots();
  }

  /// Get a live stream of newly elected officials (results) for a specific election
  Stream<QuerySnapshot> getElectionResultsStream(String electionId) {
    return _firestore
        .collection('elections')
        .doc(electionId)
        .collection('results')
        .orderBy('rank', descending: false)
        .snapshots();
  }
  
  /// Get a live stream of current university-wide officials
  Stream<QuerySnapshot> getUniversityOfficialsStream() {
    return _firestore
        .collection('university_officials')
        .orderBy('rank', descending: false) 
        .snapshots();
  }
}