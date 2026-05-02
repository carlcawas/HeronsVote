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
    String? sourceCollection,
    String? sourceDocId,
  }) async {
    final String normalizedType = electionType.toLowerCase();
    final bool isProposal = normalizedType == 'proposal';
    final bool byCollege = normalizedType == 'university' || isProposal;

    String collectionName = 'elections';
    String targetDocId = electionId;
    final bool useArchiveSource =
        sourceCollection == 'archives' && sourceDocId != null;
    if (useArchiveSource) {
      collectionName = 'archives';
      targetDocId = sourceDocId ?? electionId;
    } else {
      collectionName = isProposal ? 'proposals' : 'elections';
    }

    try {
      List<String> categoriesToCount = [];
      if (byCollege) {
        final collegesSnapshot = await _firestore.collection('colleges').get();
        if (collegesSnapshot.docs.isNotEmpty) {
          categoriesToCount = collegesSnapshot.docs.map((doc) => doc.id).toList();
        } else {
          categoriesToCount = _defaultCollegeBuckets();
        }
      } else {
        categoriesToCount = _defaultYearBuckets();
      }

      final Map<String, int> turnoutCounts = {
        for (final category in categoriesToCount) category: 0,
      };

      final List<Future<void>> voteTasks = categoriesToCount.map((category) async {
        Query voteQuery = _firestore
            .collection(collectionName)
            .doc(targetDocId)
            .collection('votes');

        if (byCollege) {
          voteQuery = voteQuery.where('user_college_id', isEqualTo: category);
        } else {
          voteQuery = voteQuery.where('user_year_level', isEqualTo: category);
          if (userCollege != null && userCollege.trim().isNotEmpty) {
            voteQuery = voteQuery.where('user_college_id', isEqualTo: userCollege);
          }
        }

        final snapshot = await voteQuery.count().get();
        turnoutCounts[category] = snapshot.count ?? 0;
      }).toList();
      await Future.wait(voteTasks);

      final Map<String, int> groupTotalVoters = {};
      final List<Future<void>> userTasks = categoriesToCount.map((category) async {
        Query<Map<String, dynamic>> query = _firestore
            .collection('users')
            .where('isVerified', isEqualTo: true);

        if (byCollege) {
          query = query.where('college_id', isEqualTo: category);
        } else {
          query = query.where('year_level', isEqualTo: category);
          if (userCollege != null && userCollege.trim().isNotEmpty) {
            query = query.where('college_id', isEqualTo: userCollege);
          }
        }

        final snapshot = await query.count().get();
        groupTotalVoters[category] = snapshot.count ?? 0;
      }).toList();
      await Future.wait(userTasks);

      final int totalVotesCast =
          turnoutCounts.values.fold(0, (total, value) => total + value);
      final int totalVerifiedVoters =
          groupTotalVoters.values.fold(0, (total, value) => total + value);

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
    String? sourceCollection,
    String? sourceDocId,
  }) async {
    final String normalizedType = electionType.toLowerCase();
    final bool isProposal = normalizedType == 'proposal';
    final bool useArchiveSource =
        sourceCollection == 'archives' && sourceDocId != null;
    final String baseCollectionPath = useArchiveSource
        ? 'archives'
        : (isProposal ? 'proposals' : 'elections');
    final String targetDocId = useArchiveSource
        ? (sourceDocId ?? electionId)
        : electionId;

    try {
      final Map<String, Map<String, dynamic>> groupedResults = {};
      final Map<String, int> positionHierarchy = {};
      final Map<String, Map<String, dynamic>> candidateLookupByNamePosition = {};

      final Future<QuerySnapshot> statsFuture = _firestore
          .collection(baseCollectionPath)
          .doc(targetDocId)
          .collection('stats')
          .get();

      final Future<QuerySnapshot> candidatesFuture = _firestore
          .collection('candidates')
          .where(
            'election_id',
            isEqualTo: electionId,
          )
          .get();

      final Future<DocumentSnapshot<Map<String, dynamic>>> electionDocFuture =
          _firestore.collection(baseCollectionPath).doc(targetDocId).get();

      final results = await Future.wait([
        statsFuture,
        candidatesFuture,
        electionDocFuture,
      ]);
      final statsSnapshot = results[0] as QuerySnapshot;
      final candidatesSnapshot = results[1] as QuerySnapshot;
      final electionDoc = results[2] as DocumentSnapshot<Map<String, dynamic>>;
      final electionData = electionDoc.data() ?? {};
      final proposalPositionTitle =
          (electionData['name'] ?? electionData['title'] ?? 'Proposal Votes')
              .toString();

      void ensurePosition(String position, int fallbackRank) {
        if (!groupedResults.containsKey(position)) {
          groupedResults[position] = {
            'candidates': <Map<String, dynamic>>[],
            'rank': fallbackRank,
          };
        }
        final existingRank = groupedResults[position]!['rank'] as int;
        if (fallbackRank < existingRank) {
          groupedResults[position]!['rank'] = fallbackRank;
        }
      }

      void upsertCandidate({
        required String position,
        required String rawName,
        int votes = 0,
        String slate = '',
        int fallbackRank = 999,
      }) {
        final candidateName = rawName.trim().isEmpty ? 'Unknown' : rawName.trim();
        ensurePosition(position, fallbackRank);
        final key = '${position.toLowerCase()}|${candidateName.toLowerCase()}';
        final existing = candidateLookupByNamePosition[key];
        if (existing != null) {
          existing['votes'] = votes;
          if ((existing['slate'] as String?)?.trim().isEmpty ?? true) {
            existing['slate'] = slate;
          }
          return;
        }

        final row = {
          'name': candidateName,
          'votes': votes,
          'isWinner': false,
          'slate': slate,
        };
        (groupedResults[position]!['candidates'] as List<Map<String, dynamic>>).add(
          row,
        );
        candidateLookupByNamePosition[key] = row;
      }

      // 1) Initialize all positions/candidates from canonical candidates collection (vote=0).
      for (var doc in candidatesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String position = (data['position'] ?? 'Unknown Position').toString();
        final String candidateName = (data['name'] ?? 'Unknown').toString();
        final int dbRank = (data['pos_rank'] as num?)?.toInt() ?? 999;
        final int canonicalRank = _positionRankFromName(position);
        final int rank = canonicalRank == 999 ? dbRank : canonicalRank;
        final String slate =
            (data['slate'] ?? data['partylist'] ?? 'Independent').toString();

        if (!positionHierarchy.containsKey(position) ||
            rank < (positionHierarchy[position] ?? 999)) {
          positionHierarchy[position] = rank;
        }

        upsertCandidate(
          position: position,
          rawName: candidateName,
          votes: 0,
          slate: slate,
          fallbackRank: positionHierarchy[position] ?? rank,
        );
      }

      // 2) Overlay stat counts (if present).
      for (var doc in statsSnapshot.docs) {
        if (doc.id == 'general') continue;

        final data = doc.data() as Map<String, dynamic>;

        final String groupKey = isProposal
            ? (data['position'] ?? proposalPositionTitle).toString()
            : (data['position'] ?? 'Unknown Position').toString();

        final int votes = (data['total_votes'] as num?)?.toInt() ?? 0;
        final String candidateName = (data['name'] ?? 'Unknown').toString();
        final String slate =
            (data['slate'] ?? data['partylist'] ?? 'Independent').toString();

        final int groupRank = positionHierarchy[groupKey] ??
            (_positionRankFromName(groupKey) == 999
                ? 999
                : _positionRankFromName(groupKey));
        ensurePosition(groupKey, groupRank);

        upsertCandidate(
          position: groupKey,
          rawName: candidateName,
          votes: votes,
          slate: slate,
          fallbackRank: groupRank,
        );
      }

      // 3) Ensure default rows/positions exist.
      if (isProposal) {
        final String proposalPosition = groupedResults.isNotEmpty
            ? groupedResults.keys.first
            : proposalPositionTitle;
        ensurePosition(proposalPosition, _positionRankFromName(proposalPosition));
        upsertCandidate(
          position: proposalPosition,
          rawName: 'Yes',
          votes: _readExistingVotes(
            position: proposalPosition,
            name: 'Yes',
            lookup: candidateLookupByNamePosition,
          ),
          fallbackRank: _positionRankFromName(proposalPosition),
        );
        upsertCandidate(
          position: proposalPosition,
          rawName: 'No',
          votes: _readExistingVotes(
            position: proposalPosition,
            name: 'No',
            lookup: candidateLookupByNamePosition,
          ),
          fallbackRank: _positionRankFromName(proposalPosition),
        );
      } else {
        for (final position in _defaultPositionOrder()) {
          ensurePosition(position, _positionRankFromName(position));
        }
      }

      groupedResults.forEach((position, result) {
        final List<Map<String, dynamic>> candidates =
            result['candidates'] as List<Map<String, dynamic>>;

        // Keep exactly one Abstain row (preserve highest votes if duplicates exist).
        int abstainVotes = 0;
        String abstainSlate = 'Independent';
        candidates.removeWhere((candidate) {
          final isAbstain =
              (candidate['name']?.toString().toLowerCase().trim() ?? '') ==
              'abstain';
          if (isAbstain) {
            final value = (candidate['votes'] as num?)?.toInt() ?? 0;
            if (value > abstainVotes) abstainVotes = value;
            abstainSlate = (candidate['slate']?.toString() ?? abstainSlate);
          }
          return isAbstain;
        });
        candidateLookupByNamePosition
            .remove('${position.toLowerCase()}|abstain');
        upsertCandidate(
          position: position,
          rawName: 'Abstain',
          votes: abstainVotes,
          slate: abstainSlate,
          fallbackRank: result['rank'] as int,
        );

        final refreshedCandidates =
            groupedResults[position]!['candidates'] as List<Map<String, dynamic>>;

        refreshedCandidates.sort((a, b) {
          final nameA = (a['name'] ?? '').toString();
          final nameB = (b['name'] ?? '').toString();
          final isAbstainA = nameA.toLowerCase() == 'abstain';
          final isAbstainB = nameB.toLowerCase() == 'abstain';
          if (isAbstainA && !isAbstainB) return 1;
          if (!isAbstainA && isAbstainB) return -1;

          final votesA = (a['votes'] as num?)?.toInt() ?? 0;
          final votesB = (b['votes'] as num?)?.toInt() ?? 0;
          if (votesA != votesB) return votesB.compareTo(votesA);

          final slateA = _normalizedSlate(a['slate']?.toString());
          final slateB = _normalizedSlate(b['slate']?.toString());
          if (slateA != slateB) return slateA.compareTo(slateB);

          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        });

        final maxVotes = refreshedCandidates.isEmpty
            ? 0
            : refreshedCandidates
                  .map((c) => (c['votes'] as num?)?.toInt() ?? 0)
                  .reduce((a, b) => a > b ? a : b);

        for (final candidate in refreshedCandidates) {
          if (maxVotes <= 0) {
            candidate['isWinner'] = false;
          } else {
            candidate['isWinner'] =
                ((candidate['votes'] as num?)?.toInt() ?? 0) == maxVotes;
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
        final rankA = a['rank'] as int;
        final rankB = b['rank'] as int;
        return rankA.compareTo(rankB);
      });

      return finalResults;
    } catch (e, s) {
      print(s);
      return [];
    }
  }

  int _readExistingVotes({
    required String position,
    required String name,
    required Map<String, Map<String, dynamic>> lookup,
  }) {
    final key = '${position.toLowerCase()}|${name.toLowerCase()}';
    return (lookup[key]?['votes'] as num?)?.toInt() ?? 0;
  }

  String _normalizedSlate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty || value.toLowerCase() == 'independent') {
      return 'zzzz_independent';
    }
    return value.toLowerCase();
  }

  List<String> _defaultYearBuckets() {
    return const ['First Year', 'Second Year', 'Third Year', 'Fourth Year'];
  }

  List<String> _defaultCollegeBuckets() {
    return const [
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

  List<String> _defaultPositionOrder() {
    return const [
      'Chairperson',
      'Vice Chairperson',
      'Secretary',
      'Treasurer',
      'Auditor',
      '1st Year Representative',
      '2nd Year Representative',
      '3rd Year Representative',
      '4th Year Representative',
    ];
  }

  int _positionRankFromName(String position) {
    final p = position.toLowerCase().trim();
    final fixed = <String, int>{
      'chairperson': 10,
      'vice chairperson': 20,
      'secretary': 30,
      'treasurer': 40,
      'auditor': 50,
    };
    if (fixed.containsKey(p)) return fixed[p]!;

    final match = RegExp(r'(\d+)(st|nd|rd|th)\s+year').firstMatch(p);
    if (match != null) {
      final year = int.tryParse(match.group(1) ?? '') ?? 99;
      return 100 + year;
    }
    return 999;
  }
}

