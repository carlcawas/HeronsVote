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

  /// Get a live stream of newly elected officials (results) for a specific election
  Stream<QuerySnapshot> getElectionResultsStream(String collegeId) {
    return _firestore
        .collection('colleges')
        .doc(collegeId)
        .collection('officials')
        .orderBy('pos_rank', descending: false)
        .snapshots();
  }

  /// Gets a stream of the single latest university election (ongoing or ended).
  Stream<QuerySnapshot> getLatestUniversityElection() {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'university')
        .orderBy('end', descending: true)
        .limit(1)
        .snapshots();
  }

  /// Gets a stream of the single latest college election (ongoing or ended).
  Stream<QuerySnapshot> getLatestCollegeElection(String collegeId) {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'college')
        .where('college_id', isEqualTo: collegeId)
        .orderBy('end', descending: true)
        .limit(1)
        .snapshots();
  }

  /// Get img of an official from college
  Future<String?> getOfficialImage(String collegeId, String officialId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('colleges')
          .doc(collegeId)
          .collection('officials')
          .doc(officialId)
          .get();

      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['img'] as String?;
      } else {
        print('Official document not found: $collegeId/officials/$officialId');
        return null; // Document not found
      }
    } catch (e) {
      print('Error getting official image field: $e');
      return null; // Error occurred
    }
  }

  /// Get img of an slate from election
  Future<String?> getSlateImage(String electionId, String slatesId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('elections')
          .doc(electionId)
          .collection('slates')
          .doc(slatesId)
          .get();

      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['img'] as String?;
      } else {
        print('Official document not found: $electionId/slates/$slatesId');
        return null; // Document not found
      }
    } catch (e) {
      print('Error getting slates img field: $e');
      return null; // Error occurred
    }
  }

  /// Gets announcements less than 6 months old
  Future<QuerySnapshot> getAnnouncements() {

    final retentionDate = DateTime.now().subtract(Duration(days: 6 * 30));
    final cutoffTimestamp = Timestamp.fromDate(retentionDate);

    return _firestore
        .collection('announcements')
        .where('posted_at', isGreaterThan: cutoffTimestamp)
        .orderBy('posted_at', descending: true)
        .get();
  }

  // Gets a one-time fetch of read announcements for a specific user
  Future<DocumentSnapshot> getReadAnnouncements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('read_status')
        .doc('read_announcements')
        .get();
  }

  /// Get a live stream of ALL proposals --- can add .where('ongoing', isEqualTo: true)
  Stream<QuerySnapshot> getAllProposalsStream() {
    return _firestore
        .collection('proposals')
        .where('ongoing', isEqualTo: true)
        .orderBy('start', descending: true)
        .snapshots();
  }

  /// Get a live stream of candidates filtered by their position/role.
  Stream<QuerySnapshot> getCandidatesByPositionStream(String positionTitle, String collegeId) {
    return _firestore
        .collection('candidates')
        .where('position', isEqualTo: positionTitle)
        .orderBy('slate')
        .where('college_id', isEqualTo: collegeId)
        .snapshots();
  }

  Stream<QuerySnapshot> getUSCCandidatesStream() {
    return _firestore
        .collection('candidates')
        .where('college_id', isEqualTo: "")
        .orderBy('pos_rank') 
        .snapshots();
  }

  /// Get a live stream of current officials for a specific college (CSC)
  Stream<QuerySnapshot> getCurrentOfficialsStream(String collegeId) {
    return _firestore
        .collection('colleges')
        .doc(collegeId)
        .collection('officials')
        .orderBy('pos_rank', descending: false)
        .snapshots();
  }

  /// Get a live stream of current university-wide officials (USC)
  Stream<QuerySnapshot> getUniversityOfficialsStream() {
    return _firestore
        .collection('university_officials')
        .orderBy('pos_rank', descending: false)
        .snapshots();
  }

  /// Get all active elections
  Future<List<Map<String, dynamic>>> getActiveElectionsForUser(String uid) async {
    List<Map<String, dynamic>> activeElections = [];

    try {
      // Get User's College ID first
      String? collegeId;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        collegeId = (userDoc.data() as Map<String, dynamic>)['college_id'];
      }

      // Get Active University Elections
      QuerySnapshot uscSnapshot = await _firestore
          .collection('elections')
          .where('type', isEqualTo: 'university')
          .where('ongoing', isEqualTo: true)
          .get();
      
      for (var doc in uscSnapshot.docs) {
        activeElections.add({
          'id': doc.id,
          'type': 'university',
          'title': (doc.data() as Map<String, dynamic>)['name'] ?? 'University Election',
           ...doc.data() as Map<String, dynamic>
        });
      }

      // Get Active College Elections
      if (collegeId != null && collegeId.isNotEmpty) {
        QuerySnapshot cscSnapshot = await _firestore
            .collection('elections')
            .where('type', isEqualTo: 'college')
            .where('college_id', isEqualTo: collegeId)
            .where('ongoing', isEqualTo: true)
            .get();

        for (var doc in cscSnapshot.docs) {
          activeElections.add({
            'id': doc.id,
            'type': 'college',
            'title': (doc.data() as Map<String, dynamic>)['name'] ?? 'College Election',
            ...doc.data() as Map<String, dynamic>
          });
        }
      }

      // Get Active Proposals
      QuerySnapshot propSnapshot = await _firestore
          .collection('proposals')
          .where('ongoing', isEqualTo: true)
          .get();

      for (var doc in propSnapshot.docs) {
        activeElections.add({
          'id': doc.id,
          'type': 'proposal',
          'title': (doc.data() as Map<String, dynamic>)['name'] ?? 'Proposal Voting',
          ...doc.data() as Map<String, dynamic>
        });
      }

    } catch (e) {
      print("Error fetching active elections: $e");
    }

    return activeElections;
  }

  /// Get candidates of a specific election using its id
  Stream<QuerySnapshot> getCandidatesByElectionId(String electionId) {
    return _firestore
        .collection('candidates')
        .where('election_id', isEqualTo: electionId)
        .orderBy('pos_rank')
        .snapshots();
  }

  Future<List<String>> getReadAnnouncementIds(String userId) async {
    final readDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('read_status')
        .doc('read_announcements');

    final readDocSnapshot = await readDocRef.get();

    if (!readDocSnapshot.exists) {
      // Create the document if it doesn't exist
      await readDocRef.set({
        'announcement_ids': [],
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return [];
    } else {
      // Fetch the IDs
      return List<String>.from(
        readDocSnapshot.get('announcement_ids') ?? [],
      );
    }
  }

  /// Atomically adds an announcement ID to the user's read list using a transaction.
  Future<void> markAnnouncementAsRead({
    required String userId,
    required String announcementId,
  }) async {
    final readDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('read_status')
        .doc('read_announcements');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(readDocRef);

      if (!snapshot.exists) {
        // If the doc doesn't exist (edge case, but handled here for safety)
        transaction.set(readDocRef, {
          'announcement_ids': [announcementId],
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        final currentIds = snapshot.get('announcement_ids') ?? [];
        final idsList = currentIds is List
            ? List<String>.from(currentIds)
            : [];

        // Only update if the ID is not already present
        if (!idsList.contains(announcementId)) {
          transaction.update(readDocRef, {
            'announcement_ids': FieldValue.arrayUnion([announcementId]),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }
}
