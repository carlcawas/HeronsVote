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
  Stream<QuerySnapshot> getElectionResultsStream(String electionId) {
    return _firestore
        .collection('elections')
        .doc(electionId)
        .collection('results')
        .orderBy('rank', descending: false)
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
        .orderBy('rank', descending: false)
        .snapshots();
  }

  /// Get a live stream of current university-wide officials (USC)
  Stream<QuerySnapshot> getUniversityOfficialsStream() {
    return _firestore
        .collection('university_officials')
        .orderBy('rank', descending: false)
        .snapshots();
  }

  /// Get all active elections
  Future<List<Map<String, dynamic>>> getActiveElectionsForUser(
    String uid,
  ) async {
    List<Map<String, dynamic>> activeElections = [];

    try {
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
          .where('ongoing', isEqualTo: true)
          .get();

      for (var doc in uscSnapshot.docs) {
        activeElections.add({
          'id': doc.id,
          'type': 'university',
          'title':
              (doc.data() as Map<String, dynamic>)['name'] ??
              'University Election',
          ...doc.data() as Map<String, dynamic>,
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
            'title':
                (doc.data() as Map<String, dynamic>)['name'] ??
                'College Election',
            ...doc.data() as Map<String, dynamic>,
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
          'title':
              (doc.data() as Map<String, dynamic>)['name'] ?? 'Proposal Voting',
          ...doc.data() as Map<String, dynamic>,
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
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    List<Map<String, dynamic>> filteredList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? endTimeStamp = data['end'] as Timestamp?;

      if (endTimeStamp != null && endTimeStamp.toDate().isAfter(sevenDaysAgo)) {
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
      final snapshot = await getActiveUniversityElectionStream().first;
      return _mapSnapshotToElections(snapshot, 'university');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveCollegeElections(
    String? collegeId,
  ) async {
    if (collegeId == null) return [];
    try {
      final snapshot = await getActiveCollegeElectionStream(collegeId).first;
      return _mapSnapshotToElections(snapshot, 'college');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getActiveUniversityProposals() async {
    try {
      final snapshot = await getActiveUniversityProposalStream().first;
      return _mapSnapshotToElections(snapshot, 'proposal');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>>
  getRecentlyEndedUniversityElections() async {
    try {
      final snapshot = await getRecentlyEndedUniversityElection().first;
      return _processRecentResults(snapshot, 'university_ended');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentlyEndedCollegeElections(
    String collegeId,
  ) async {
    try {
      final snapshot = await getRecentlyEndedCollegeElection(collegeId).first;
      return _processRecentResults(snapshot, 'college_ended');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>>
  getRecentlyEndedUniversityProposals() async {
    try {
      final snapshot = await getRecentlyEndedUniversityProposal().first;
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

      Map<String, int> positionHierarchy = {};

      for (var doc in candidatesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String position = data['position'] ?? 'Unknown';

        // Debug Raw Value
        final dynamic rawRank = data['pos_rank'];

        // Safe Parse
        final int rank = (rawRank as num?)?.toInt() ?? 999;

        positionHierarchy[position] = rank;

      }

      for (var doc in statsSnapshot.docs) {
        if (doc.id == 'general') continue;

        final data = doc.data() as Map<String, dynamic>;

        final String groupKey = (electionType == 'proposal')
            ? 'CBL'
            : data['position'] ?? 'Unknown Position';

        final int votes = (data['total_votes'] as num?)?.toInt() ?? 0;
        final String candidateName = data['name'] ?? 'Unknown';

        final int groupRank = positionHierarchy[groupKey] ?? 999;

        final Map<String, dynamic> candidateData = {
          'name': candidateName,
          'votes': votes,
          'isWinner': false,
        };

        if (!groupedResults.containsKey(groupKey)) {
          groupedResults[groupKey] = {
            'candidates': <Map<String, dynamic>>[],
            'rank': groupRank,
          };
        }

        groupedResults[groupKey]!['candidates'].add(candidateData);
      }

      groupedResults.forEach((groupKey, result) {
        final List<Map<String, dynamic>> candidates =
            result['candidates'] as List<Map<String, dynamic>>;

        final bool hasAbstain = candidates.any((c) => c['name'] == 'Abstain');
        if (!hasAbstain) {
          candidates.add({'name': 'Abstain', 'votes': 0, 'isWinner': false});
        }

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
