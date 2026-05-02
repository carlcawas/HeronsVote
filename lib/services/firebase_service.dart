import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heronsvote/model/turnout_model.dart';

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

  DateTime? _asDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  bool _isWithinVotingWindow(Map<String, dynamic> data, DateTime now) {
    final start = _asDateTime(data['start']);
    final end = _asDateTime(data['end']);
    if (start == null || end == null) return false;
    return !now.isBefore(start) && !now.isAfter(end);
  }

  bool _isWithinResultsClosedWindow(Map<String, dynamic> data, DateTime now) {
    final end = _asDateTime(data['end']);
    if (end == null) return false;
    final twoWeeksAfterEnd = end.add(const Duration(days: 14));
    return now.isAfter(end) && !now.isAfter(twoWeeksAfterEnd);
  }
  /// Get specific field value === example use:
  /// String user_name = getField(users, uid, name)
  /// === where users is collection, uid should be unique, name is field
  Future<dynamic> getField(
    String collection,
    String docId,
    String field,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(collection)
          .doc(docId)
          .get();
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
    String collection,
    String docId,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(collection)
          .doc(docId)
          .get();
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
    String collection,
    String field,
    dynamic value,
  ) async {
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
        .where('isDraft', isEqualTo: false)
        .where('ongoing', isEqualTo: true)
        .where('status', isEqualTo: 'Ongoing')
        .limit(1)
        .snapshots();
  }

  /// Gets a live stream of the active university-wide election.
  Stream<QuerySnapshot> getActiveUniversityElectionStream() {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'university')
        .where('isDraft', isEqualTo: false)
        .where('ongoing', isEqualTo: true)
        .where('status', isEqualTo: 'Ongoing')
        .limit(1)
        .snapshots();
  }

  /// Gets a live stream of the active university-wide proposal.
  Stream<QuerySnapshot> getActiveUniversityProposalStream() {
    return _firestore
        .collection('proposals')
        .where('isDraft', isEqualTo: false)
        .where('ongoing', isEqualTo: true)
        .where('status', isEqualTo: 'Ongoing')
        .limit(1)
        .snapshots();
  }

  /// Gets a stream of recently ended college elections (ended within the last 7 days).
  Stream<QuerySnapshot> getRecentlyEndedCollegeElection(String collegeId) {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'college')
        .where('college_id', isEqualTo: collegeId)
        .where('isDraft', isEqualTo: false)
        .where('ongoing', isEqualTo: false)
        .where('status', isEqualTo: 'Closed')
        .orderBy('end', descending: true) // Get the most recent one
        .limit(1)
        .snapshots();
  }

  /// Gets a stream of recently ended university elections (ended within the last 7 days).
  Stream<QuerySnapshot> getRecentlyEndedUniversityElection() {
    return _firestore
        .collection('elections')
        .where('type', isEqualTo: 'university')
        .where('isDraft', isEqualTo: false)
        .where('ongoing', isEqualTo: false)
        .where('status', isEqualTo: 'Closed')
        .orderBy('end', descending: true) // Get the most recent one
        .limit(1)
        .snapshots();
  }

  /// Gets recently ended university proposals (ended within the last 7 days).
  Stream<QuerySnapshot> getRecentlyEndedUniversityProposal() {
    return _firestore
        .collection('proposals')
        .where('isDraft', isEqualTo: false)
        .where('ongoing', isEqualTo: false)
        .where('status', isEqualTo: 'Closed')
        .orderBy('end', descending: true)
        .limit(1)
        .snapshots();
  }

  /// Get a live stream of all slates for a specific election
  Stream<QuerySnapshot> getSlatesStream(String electionId) {
    return _firestore
        .collection('slates')
        .where('election_id', isEqualTo: electionId)
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

  /// Get img of a slate from top-level slates collection
  Future<String?> getSlateImage(String electionId, String slatesId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('slates')
          .doc(slatesId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['election_id'] == electionId) {
          return data['img'] as String?;
        }
        print('Slate does not belong to election:  / ');
        return null;
      } else {
        print('Slate document not found: slates/');
        return null;
      }
    } catch (e) {
      print('Error getting slates img field: ');
      return null;
    }
  }

  /// Gets announcements visible to voters: status 'Published' and
  /// scheduledDate <= now (scheduled date onwards).
  Future<QuerySnapshot> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('status', isEqualTo: 'Published')
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
        .where('isDraft', isEqualTo: false)
        .where('ongoing', isEqualTo: true)
        .where('status', isEqualTo: 'Ongoing')
        .orderBy('start', descending: true)
        .snapshots();
  }

  /// Get a live stream of candidates filtered by their position/role.
  Stream<QuerySnapshot> getCandidatesByPositionStream(
    String positionTitle,
    String collegeId,
  ) {
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

  /// Get all active elections for Voting tab.
  /// Visible only while now is between start and end timestamps.
  Future<List<Map<String, dynamic>>> getActiveElectionsForUser(
    String uid,
  ) async {
    List<Map<String, dynamic>> activeElections = [];

    try {
      final now = DateTime.now();

      // Get User's College ID first
      String? collegeId;
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        collegeId = (userDoc.data() as Map<String, dynamic>)['college_id'];
      }

      // Get Active University Elections
      QuerySnapshot uscSnapshot = await _firestore
          .collection('elections')
          .where('type', isEqualTo: 'university')
          .where('isDraft', isEqualTo: false)
          .where('ongoing', isEqualTo: true)
          .where('status', isEqualTo: 'Ongoing')
          .get();

      for (var doc in uscSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!_isWithinVotingWindow(data, now)) continue;
        activeElections.add({
          'id': doc.id,
          'type': 'university',
          'title': data['name'] ?? 'University Election',
          ...data,
        });
      }

      // Get Active College Elections
      if (collegeId != null && collegeId.isNotEmpty) {
        QuerySnapshot cscSnapshot = await _firestore
            .collection('elections')
            .where('type', isEqualTo: 'college')
            .where('college_id', isEqualTo: collegeId)
            .where('isDraft', isEqualTo: false)
            .where('ongoing', isEqualTo: true)
            .where('status', isEqualTo: 'Ongoing')
            .get();

        for (var doc in cscSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (!_isWithinVotingWindow(data, now)) continue;
          activeElections.add({
            'id': doc.id,
            'type': 'college',
            'title': data['name'] ?? 'College Election',
            ...data,
          });
        }
      }

      // Get Active Proposals
      QuerySnapshot propSnapshot = await _firestore
          .collection('proposals')
          .where('isDraft', isEqualTo: false)
          .where('ongoing', isEqualTo: true)
          .where('status', isEqualTo: 'Ongoing')
          .get();

      for (var doc in propSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!_isWithinVotingWindow(data, now)) continue;
        activeElections.add({
          'id': doc.id,
          'type': 'proposal',
          'title': data['name'] ?? 'Proposal Voting',
          ...data,
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
      return List<String>.from(readDocSnapshot.get('announcement_ids') ?? []);
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
        final idsList = currentIds is List ? List<String>.from(currentIds) : [];

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

  // HELPER 1: Update this function
  List<Map<String, dynamic>> _mapSnapshotToElections(
    QuerySnapshot snapshot,
    String type,
  ) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'type': type,

        // FIX: Explicitly map 'name' from DB to 'title' for the UI
        'title': data['name'] ?? 'Untitled Election',

        ...data, // Spread the rest of the data (e.g. start, end, description)
      };
    }).toList();
  }

  List<Map<String, dynamic>> _processRecentResults(
    QuerySnapshot snapshot,
    String type,
  ) {
    final now = DateTime.now();
    List<Map<String, dynamic>> filteredList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (_isWithinResultsClosedWindow(data, now)) {
        filteredList.add({
          'id': doc.id,
          'type': type,
          'title': data['name'] ?? 'Ended Election',
          ...data,
        });
      }
    }
    return filteredList;
  }

  //Trust the process
  Future<List<Map<String, dynamic>>> getActiveUniversityElections() async {
    try {
      final snapshot = await _firestore
          .collection('elections')
          .where('type', isEqualTo: 'university')
          .where('isDraft', isEqualTo: false)
          .where('ongoing', isEqualTo: true)
          .where('status', isEqualTo: 'Ongoing')
          .get();
      final now = DateTime.now();
      return _mapSnapshotToElections(snapshot, 'university')
          .where((item) => _isWithinVotingWindow(item, now))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveCollegeElections(
    String? collegeId,
  ) async {
    if (collegeId == null) return [];
    try {
      final snapshot = await _firestore
          .collection('elections')
          .where('type', isEqualTo: 'college')
          .where('college_id', isEqualTo: collegeId)
          .where('isDraft', isEqualTo: false)
          .where('ongoing', isEqualTo: true)
          .where('status', isEqualTo: 'Ongoing')
          .get();
      final now = DateTime.now();
      return _mapSnapshotToElections(snapshot, 'college')
          .where((item) => _isWithinVotingWindow(item, now))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getActiveUniversityProposals() async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('isDraft', isEqualTo: false)
          .where('ongoing', isEqualTo: true)
          .where('status', isEqualTo: 'Ongoing')
          .get();
      final now = DateTime.now();
      return _mapSnapshotToElections(snapshot, 'proposal')
          .where((item) => _isWithinVotingWindow(item, now))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>>
  getRecentlyEndedUniversityElections() async {
    try {
      final snapshot = await _firestore
          .collection('elections')
          .where('type', isEqualTo: 'university')
          .where('isDraft', isEqualTo: false)
          .where('ongoing', isEqualTo: false)
          .where('status', isEqualTo: 'Closed')
          .orderBy('end', descending: true)
          .get();
      return _processRecentResults(snapshot, 'university_ended');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentlyEndedCollegeElections(
    String collegeId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('elections')
          .where('type', isEqualTo: 'college')
          .where('college_id', isEqualTo: collegeId)
          .where('isDraft', isEqualTo: false)
          .where('ongoing', isEqualTo: false)
          .where('status', isEqualTo: 'Closed')
          .orderBy('end', descending: true)
          .get();
      return _processRecentResults(snapshot, 'college_ended');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>>
  getRecentlyEndedUniversityProposals() async {
    try {
      final snapshot = await _firestore
          .collection('proposals')
          .where('isDraft', isEqualTo: false)
          .where('ongoing', isEqualTo: false)
          .where('status', isEqualTo: 'Closed')
          .orderBy('end', descending: true)
          .get();
      return _processRecentResults(snapshot, 'proposal_ended');
    } catch (e) {
      return [];
    }
  }

  // Main Orchestrating function

  Future<List<Map<String, dynamic>>> getRelevantElectionsForUser(
    String uid,
  ) async {
    List<Map<String, dynamic>> relevantElections = [];

    String? collegeId;

    // 1. Fetch User Context
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    if (userDoc.exists && userDoc.data() != null) {
      final userData = userDoc.data() as Map<String, dynamic>;
      collegeId = userData['college_id'] as String?;
    }

    // 2. Fetch Global Events (No collegeId needed)
    relevantElections.addAll(await getActiveUniversityElections());
    relevantElections.addAll(await getActiveUniversityProposals());
    relevantElections.addAll(await getRecentlyEndedUniversityElections());
    relevantElections.addAll(await getRecentlyEndedUniversityProposals());

    // 3. Fetch Local/College Events (collegeId is required)
    if (collegeId != null) {
      relevantElections.addAll(await fetchActiveCollegeElections(collegeId));
      relevantElections.addAll(
        await getRecentlyEndedCollegeElections(collegeId),
      );
    }

    return relevantElections;
  }

  Future<TurnoutStats> getTurnoutDataStream({
    required String electionId,
    required String electionType,
    String? userCollege,
  }) async {
    String collectionName = 'elections';

    List<String> categoriesToCount = [];

    try {
      // --- 1. SETUP CATEGORIES ---
      if (electionType == 'university') {
        final collegesSnapshot = await _firestore.collection('colleges').get();
        if (collegesSnapshot.docs.isNotEmpty) {
          categoriesToCount = collegesSnapshot.docs
              .map((doc) => doc.id)
              .toList();
        } else {
          categoriesToCount = [
            'CBFS',
            'CCIS',
            'CCSE',
            'CET',
            'CGPP',
            'CHK',
            'CITE',
            'CTHM',
            'IAD',
            'IDEM',
            'IIHS',
            'IOA',
            'ION',
            'IOP',
            'IOPSY',
            'ISW',
          ];
        }
      } else {
        // Local/Proposal Setup
        collectionName = (electionType == 'proposal')
            ? 'proposals'
            : 'elections';
        categoriesToCount = [
          'First Year',
          'Second Year',
          'Third Year',
          'Fourth Year',
        ];
      }

      Map<String, int> turnoutCounts = {};

      for (var category in categoriesToCount) {
        turnoutCounts[category] = 0;
      }

      List<Future<void>> voteTasks = categoriesToCount.map((category) async {
        Query voteQuery = _firestore
            .collection(collectionName)
            .doc(electionId)
            .collection('votes');

        // Filter votes by the category (College or Year Level)
        if (electionType == 'university') {
          voteQuery = voteQuery.where('user_college_id', isEqualTo: category);
        } else {
          voteQuery = voteQuery.where('user_year_level', isEqualTo: category);

          // Add specific college filter for local elections (e.g., CSC)
          if (userCollege != null) {
            voteQuery = voteQuery.where(
              'user_college_id',
              isEqualTo: userCollege,
            );
          }
        }

        final snapshot = await voteQuery.count().get();
        turnoutCounts[category] = snapshot.count ?? 0;
      }).toList();

      await Future.wait(voteTasks);

      // Total Voted
      final int totalVotesCast = turnoutCounts.values.fold(
        0,
        (sum, count) => sum + count,
      );

      // Count Total Users
      Map<String, int> groupTotalVoters = {};

      List<Future<void>> userTasks = categoriesToCount.map((category) async {
        Query<Map<String, dynamic>> query = _firestore
            .collection('users')
            .where('isVerified', isEqualTo: true);

        if (electionType == 'university') {
          query = query.where('college_id', isEqualTo: category);
        } else {
          query = query.where('year_level', isEqualTo: category);

          if (userCollege != null) {
            query = query.where('college_id', isEqualTo: userCollege);
          }
        }

        final snapshot = await query.count().get();
        groupTotalVoters[category] = snapshot.count ?? 0;
      }).toList();

      await Future.wait(userTasks);

      final int totalVerifiedVoters = groupTotalVoters.values.fold(
        0,
        (sum, count) => sum + count,
      );

      return TurnoutStats(
        breakdown: turnoutCounts,
        groupTotalVoters: groupTotalVoters,
        totalVotesCast: totalVotesCast,
        totalVerifiedVoters: totalVerifiedVoters,
      );
    } catch (e, stacktrace) {
      print('--- ERROR in getTurnoutDataStream ---');
      print('Error: $e');
      print('Stacktrace: $stacktrace');

      return TurnoutStats(
        breakdown: {},
        groupTotalVoters: {},
        totalVotesCast: 0,
        totalVerifiedVoters: 1,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getElectionDataStream({
    required String electionId,
    required String electionType,
  }) async {
    final String baseCollectionPath = (electionType == 'proposal')
        ? 'proposals'
        : 'elections';


    final Map<String, Map<String, dynamic>> groupedResults = {};

    try {
      final Future<QuerySnapshot> statsFuture = _firestore
          .collection(baseCollectionPath)
          .doc(electionId)
          .collection('stats')
          .get();

      final Future<QuerySnapshot> candidatesFuture = _firestore
          .collection('candidates')
          .where(
            'election_id',
            isEqualTo: electionId,
          )
          .get();


      final results = await Future.wait([statsFuture, candidatesFuture]);
      final statsSnapshot = results[0];
      final candidatesSnapshot = results[1];

      final Map<String, int> positionHierarchy = {};
      final Map<String, Map<String, dynamic>> candidateLookupByNamePosition = {};

      // 1) Initialize all positions/candidates from canonical candidates collection (vote=0).
      for (var doc in candidatesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String position = data['position'] ?? 'Unknown Position';
        final String candidateName = data['name'] ?? 'Unknown';
        final int rank = (data['pos_rank'] as num?)?.toInt() ?? 999;

        if (!positionHierarchy.containsKey(position) ||
            rank < (positionHierarchy[position] ?? 999)) {
          positionHierarchy[position] = rank;
        }

        if (!groupedResults.containsKey(position)) {
          groupedResults[position] = {
            'candidates': <Map<String, dynamic>>[],
            'rank': positionHierarchy[position] ?? 999,
          };
        }

        final candidateRow = {
          'name': candidateName,
          'votes': 0,
          'isWinner': false,
        };
        (groupedResults[position]!['candidates'] as List<Map<String, dynamic>>)
            .add(candidateRow);

        final key = '${position.toLowerCase()}|${candidateName.toLowerCase()}';
        candidateLookupByNamePosition[key] = candidateRow;
      }

      // Ensure each known position has an abstain row by default (0 votes).
      groupedResults.forEach((position, result) {
        final candidates = result['candidates'] as List<Map<String, dynamic>>;
        final hasAbstain = candidates.any((c) => c['name'] == 'Abstain');
        if (!hasAbstain) {
          candidates.add({'name': 'Abstain', 'votes': 0, 'isWinner': false});
        }
      });

      // 2) Overlay stat counts (if present).
      for (var doc in statsSnapshot.docs) {
        if (doc.id == 'general') continue;

        final data = doc.data() as Map<String, dynamic>;

        final String groupKey = (electionType == 'proposal')
            ? (data['position'] ?? 'Proposal')
            : data['position'] ?? 'Unknown Position';

        final int votes = (data['total_votes'] as num?)?.toInt() ?? 0;
        final String candidateName = data['name'] ?? 'Unknown';

        final int groupRank = positionHierarchy[groupKey] ?? 999;

        if (!groupedResults.containsKey(groupKey)) {
          groupedResults[groupKey] = {
            'candidates': <Map<String, dynamic>>[],
            'rank': groupRank,
          };
        }
        // Keep rank synced for late-created groups
        groupedResults[groupKey]!['rank'] = groupRank;

        final candidates =
            groupedResults[groupKey]!['candidates'] as List<Map<String, dynamic>>;
        final key = '${groupKey.toLowerCase()}|${candidateName.toLowerCase()}';
        final existing = candidateLookupByNamePosition[key];

        if (existing != null) {
          existing['votes'] = votes;
        } else {
          // Handles stats rows not present in candidates collection (e.g. proposal Yes/No)
          final newRow = {
            'name': candidateName,
            'votes': votes,
            'isWinner': false,
          };
          candidates.add(newRow);
          candidateLookupByNamePosition[key] = newRow;
        }
      }

      groupedResults.forEach((_, result) {
        final List<Map<String, dynamic>> candidates =
            result['candidates'] as List<Map<String, dynamic>>;

        candidates.sort((a, b) {
          int votesA = a['votes'] as int;
          int votesB = b['votes'] as int;
          return votesB.compareTo(votesA);
        });

        // Mark Winner
        if (candidates.isNotEmpty) {
          if (candidates.first['name'] != 'Abstain') {
            candidates.first['isWinner'] = true;
          }
        }
      });

      List<Map<String, dynamic>> finalResults = groupedResults.entries.map((
        entry,
      ) {
        return {
          'position': entry.key,
          'candidates': entry.value['candidates'],
          'rank': entry.value['rank'],
        };
      }).toList();


      finalResults.sort((a, b) {
        int rankA = a['rank'] as int;
        int rankB = b['rank'] as int;
        return rankA.compareTo(rankB);
      });


      return finalResults;
    } catch (e, s) {
      print(s);
      return [];
    }
  }
}

