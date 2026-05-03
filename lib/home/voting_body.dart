import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'voting_models.dart';
import 'candidate_selection.dart';
import 'voting_confirmation.dart';
import '../services/firebase_service.dart';
import 'profile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Candidate list card
class ChooseCandidateCard extends StatelessWidget {
  final VoidCallback onTap;
  const ChooseCandidateCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        padding: const EdgeInsets.only(left: 32, right: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Choose your candidate',
              style: TextStyle(
                color: Color(0xFF404040),
                fontSize: 16,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              width: 39,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF5C6AA0),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Candidate vote card
class CandidateVoteCard extends StatelessWidget {
  final VotingCandidate candidate;
  final VoidCallback onTap;

  const CandidateVoteCard({
    super.key,
    required this.candidate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) { 
    if (candidate.isAbstain) { //abstain card
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 78,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7E8E9), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E8E9),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.how_to_vote_outlined,
                  color: Color(0xFF747474),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                      'Abstain',
                      style: TextStyle(
                        color: Color(0xFF404040),
                        fontSize: 16,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ),
              ),
              Container(
                  width: 39,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5C6AA0),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),

            ],
          ),
        ),
      );
    }

    String? publicUrl;
    if (candidate.img != null && candidate.img!.isNotEmpty) {
      try {
        publicUrl = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(candidate.img!);
      } catch (e) {
        publicUrl = null;
      }
    }

    return GestureDetector( //selected candidate
      onTap: onTap,
      child: Container(
        height: 78,
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7E8E9), width: 1),
        ),
        child: Row(
          children: [
            // Image Placeholder
            if (!candidate.isProposalOption) ...[
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E8E9),
                  borderRadius: BorderRadius.circular(50),
                  image: (publicUrl != null)
                      ? DecorationImage(
                          image: NetworkImage(publicUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (publicUrl == null)
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ] else ...[
              const SizedBox(width: 8),
            ],
            // Candidate Name and Partylist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    candidate.name,
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 16,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!candidate.isProposalOption) ...[
                    const SizedBox(height: 0),
                    Text(
                      (candidate.partylist.isEmpty)
                          ? 'Independent'
                          : candidate.partylist,
                      style: const TextStyle(
                        color: Color(0xFF747474),
                        fontSize: 12,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Year/College and Arrow Button
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (candidate.year.isNotEmpty)
                  Text(
                    '${candidate.year} Year',
                    style: const TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                    ),
                  ),
                if (candidate.college.isNotEmpty)
                const SizedBox(height: 2),
                  Text(
                    candidate.college,
                    style: const TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 39,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF5C6AA0),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CastVoteCard extends StatelessWidget {
  final VoidCallback onTap;
  const CastVoteCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        padding: const EdgeInsets.only(left: 32, right: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7E8E9), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cast your vote',
              style: TextStyle(
                color: Color(0xFF404040),
                fontSize: 16,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              width: 39,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF5C6AA0),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PositionVoteItem with error state
class PositionVoteItem extends StatelessWidget {
  final String positionTitle;
  final VotingCandidate? selectedCandidate;
  final VoidCallback onSelectCandidate;
  final bool hasError;
  final bool isProposal;

  const PositionVoteItem({
    super.key,
    required this.positionTitle,
    this.selectedCandidate,
    required this.onSelectCandidate,
    this.hasError = false,
    this.isProposal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      positionTitle,
                      style: const TextStyle(
                        color: Color(0xFF404040),
                        fontSize: 16,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (hasError)
                  Row(
                    children: [
                      const Text(
                        'No Chosen Candidate',
                        style: TextStyle(
                          color: Color(0xFFED6C6A),
                          fontSize: 12,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(width: 6),
                      SvgPicture.asset('assets/error.svg', height: 20, width: 20),
                    ],
                  ),
              ],
            ),
          ),
          selectedCandidate == null
              ? (isProposal
                  ? CastVoteCard(onTap: onSelectCandidate)
                  : ChooseCandidateCard(onTap: onSelectCandidate))
              : CandidateVoteCard(
                  candidate: selectedCandidate!,
                  onTap: onSelectCandidate,
                ),
        ],
      ),
    );
  }
}

class VotingCompletePageBody extends StatelessWidget {
  const VotingCompletePageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Voting Complete",
                  style: TextStyle(
                    color: Color(0xFF404040),
                    fontSize: 24,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                SvgPicture.asset('assets/check.svg', width: 28),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "You have successfully cast your vote for this election. Thank you for participating.",
              style: TextStyle(
                color: Color(0xFF747474),
                fontSize: 14,
                fontFamily: 'Geist',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//VOTING PAGE
class VotingHomePage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> electionData;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;

  const VotingHomePage({
    super.key,
    required this.uid,
    required this.electionData,
    this.onBack,
    this.onRefresh,
  });

  @override
  State<VotingHomePage> createState() => _VotingHomePageState();
}

class _VotingHomePageState extends State<VotingHomePage> {
  final Map<String, VotingCandidate?> _selectedCandidates = {};
  bool _showErrors = false;
  // CHECKER IF NAG-VOTE NA USER
  bool _hasVoted = false;
  bool _isVerified = true;
  bool _isLoadingVerification = true;

  String? _userCollege;
  String? _userYearLevel;

  late String _electionTitle;
  late String _electionPeriod;
  late String _proposalDisplayName;
  bool _isProposal = false;

  // preload information
  late Stream<QuerySnapshot> _candidateStream;

  @override
  void initState() {
    super.initState();
    _electionTitle = widget.electionData['title'] ?? 'Election Voting';
    _isProposal = widget.electionData['type'] == 'proposal';
    _proposalDisplayName = widget.electionData['proposalName'] ?? 'Proposal Name';

    // Date Handling
    if (widget.electionData['start'] != null &&
        widget.electionData['end'] != null) {
      try {
        Timestamp startTs = widget.electionData['start'];
        Timestamp endTs = widget.electionData['end'];
        String start = DateFormat('MMM d, yyyy').format(startTs.toDate());
        String end = DateFormat('MMM d, yyyy').format(endTs.toDate());
        _electionPeriod = '$start - $end';
      } catch (e) {
        _electionPeriod = '(Ongoing)';
      }
    } else {
      _electionPeriod = '(Ongoing)';
    }

    if (!_isProposal) {
      _candidateStream = FirebaseService().getCandidatesByElectionId(
        widget.electionData['id'],
      );
    } else {
      _candidateStream = const Stream.empty();
    }

    // Check if nag-vote na user
    _checkIfUserVoted();
    _checkUserStatus();

    // load saved candidates
    _loadSavedVotes();
  }

  Future<void> _loadSavedVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'draft_votes_${widget.uid}_${widget.electionData['id']}';
      final String? savedData = prefs.getString(key);

      if (savedData != null) {
        final Map<String, dynamic> decodedMap = jsonDecode(savedData);
        
        setState(() {
          decodedMap.forEach((position, candidateMap) {
            if (candidateMap != null) {
              _selectedCandidates[position] = VotingCandidate(
                id: candidateMap['id'],
                name: candidateMap['name'] ?? 'Unknown',
                role: candidateMap['role'] ?? 'Unknown',
                partylist: candidateMap['partylist'] ?? 'Independent',
                college: candidateMap['college'] ?? '',
                year: candidateMap['year'] ?? '',
                img: candidateMap['img'],
                isAbstain: candidateMap['isAbstain'] ?? false,
                isProposalOption: candidateMap['isProposalOption'] ?? false,
              );
            }
          });
        });
      }
    } catch (e) {
      debugPrint("Error loading saved votes: $e");
    }
  }

  Future<void> _saveVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'draft_votes_${widget.uid}_${widget.electionData['id']}';
      
      Map<String, dynamic> dataToSave = {};

      _selectedCandidates.forEach((position, candidate) {
        if (candidate != null) {
          dataToSave[position] = {
            'id': candidate.id,
            'name': candidate.name,
            'role': candidate.role,
            'partylist': candidate.partylist,
            'year': candidate.year,
            'college': candidate.college,
            'img': candidate.img,
            'isAbstain': candidate.isAbstain,
            'isProposalOption': candidate.isProposalOption,
          };
        }
      });

      await prefs.setString(key, jsonEncode(dataToSave));
    } catch (e) {
      debugPrint("Error saving votes: $e");
    }
  }

  Future<void> _checkIfUserVoted() async {
    try {
      final String collectionPath = _isProposal ? 'proposals' : 'elections';
      final String docId = widget.electionData['id'];

      final docSnapshot = await FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(docId)
          .collection('votes')
          .doc(widget.uid)
          .get();

      if (docSnapshot.exists && mounted) {
        setState(() {
          _hasVoted = true;
        });
        _clearSavedVotes();
      }
    } catch (e) {
      debugPrint("Error checking vote status: $e");
    }
  }

  Future<void> _checkUserStatus() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      bool verified = true;
      if (userDoc.exists) {
        final data = userDoc.data();
        verified = data?['isVerified'] ?? false;
        _userCollege = data?['college_id'];
        _userYearLevel = data?['year_level'];
      }

      final String collectionPath = _isProposal ? 'proposals' : 'elections';
      final String docId = widget.electionData['id'];

      final voteDoc = await FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(docId)
          .collection('votes')
          .doc(widget.uid)
          .get();

      if (mounted) {
        setState(() {
          _isVerified = verified;
          _hasVoted = voteDoc.exists;
          _isLoadingVerification = false;
        });
      }
    } catch (e) {
      print("Error checking status: $e");
      if (mounted) setState(() => _isLoadingVerification = false);
    }
  }

  List<VotingCandidate> _mapFirestoreToCandidates(List<DocumentSnapshot> docs) {
    return docs.map((doc) {
      return VotingCandidate.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  List<VotingCandidate> _getProposalOptions() {
    return [
      VotingCandidate(name: 'Yes', role: 'Proposal', isProposalOption: true),
      VotingCandidate(name: 'No', role: 'Proposal', isProposalOption: true),
    ];
  }

  void _handleSelectCandidate(
    String positionTitle,
    List<VotingCandidate> candidates,
  ) async {
    // disable yung selection if true yung _hasVoted
    if (_hasVoted) return;

    final VotingCandidate? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidateSelectionPage(
          positionTitle: positionTitle,
          candidates: candidates,
          initialSelection: _selectedCandidates[positionTitle],
          isProposal: _isProposal,
          electionType: widget.electionData['type'],
          userCollege: _userCollege,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedCandidates[positionTitle] = result;
        _showErrors = false;
      });
      _saveVotes();
    }
  }

  void _submitVote(List<String> positionsToCheck) {
    final hasEmpty = positionsToCheck.any(
      (pos) => _selectedCandidates[pos] == null,
    );

    if (hasEmpty) {
      setState(() => _showErrors = true);
      final missing = positionsToCheck
          .where((pos) => _selectedCandidates[pos] == null)
          .toList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Missing: ${missing.join(', ')}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoteConfirmationPage(
          selectedCandidates: _selectedCandidates,
          electionId: widget.electionData['id'],
          electionType: widget.electionData['type'] ?? 'college',
        ),
      ),
    );
  }

  Future<void> _clearSavedVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'draft_votes_${widget.uid}_${widget.electionData['id']}';
    await prefs.remove(key);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingVerification) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isVerified) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildNotVerifiedCard(),
      );
    }
    if (_hasVoted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const VotingCompletePageBody(),
      );
    }

    if (_isProposal) {
      return _buildPageLayout(const [], isProposalMode: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _candidateStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Scaffold(body: Center(child: Text("Error loading")));

        // Show loading state while pre-loading
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        var allCandidates = _mapFirestoreToCandidates(snapshot.data!.docs);

        // User's Year Level Filtering
        if (_userYearLevel != null && _userYearLevel!.isNotEmpty) {
          allCandidates = allCandidates.where((candidate) {
            final String role = candidate.role.toLowerCase();
            final String userYear = _userYearLevel!.toLowerCase();

            bool isYearRep = role.contains('representative') && role.contains('year');

            if (isYearRep) {
              String yearKeyword = userYear.split(' ')[0]; 

              String numericKeyword = '';
              if (yearKeyword == 'first') numericKeyword = '1st';
              else if (yearKeyword == 'second') numericKeyword = '2nd';
              else if (yearKeyword == 'third') numericKeyword = '3rd';
              else if (yearKeyword == 'fourth') numericKeyword = '4th';

              return role.contains(yearKeyword) || (numericKeyword.isNotEmpty && role.contains(numericKeyword));
            }

            return true;
          }).toList();
        }

        final List<String> dynamicPositions = allCandidates
            .map((c) => c.role)
            .toSet()
            .toList();

        return _buildPageLayout(allCandidates, positions: dynamicPositions);
      },
    );
  }

  Widget _buildPageLayout(List<VotingCandidate> allCandidates,
      {List<String> positions = const [], bool isProposalMode = false}) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh ?? () async {},
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 25.0,
                  right: 25.0,
                  bottom: 120.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                  // Election Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 16, left: 16, bottom: 16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(20),
                      /*boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],*/
                      border: Border.all(color: const Color(0xFFD9D9D9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _electionTitle,
                          style: const TextStyle(
                            color: Color(0xFF404040),
                            fontSize: 24,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _electionPeriod,
                          style: const TextStyle(
                            color: Color(0xFF747474),
                            fontSize: 16,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // check if _hasVoted
                        if (_hasVoted) ...[
                          const SizedBox(height: 5),
                          const Text(
                            '(You have successfully cast your vote for this election. Thank you for participating.)',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 14,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF76D675),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Ongoing',
                              style: TextStyle(
                                color: Color(0xFF747474),
                                fontSize: 14,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                    if (isProposalMode)
                      _buildProposalBody(includeButton: false)
                    else
                      Column(
                        children: positions.map((pos) {
                          final candidatesForPos = allCandidates
                              .where((c) => c.role == pos)
                              .toList();

                          if (!_selectedCandidates.containsKey(pos)) {
                            _selectedCandidates[pos] = null;
                          }

                          final hasError = _showErrors &&
                              _selectedCandidates[pos] == null;

                          return PositionVoteItem(
                            positionTitle: pos,
                            selectedCandidate: _selectedCandidates[pos],
                            onSelectCandidate: () => _handleSelectCandidate(
                              pos,
                              candidatesForPos,
                            ),
                            hasError: hasError,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                left: 25,
                right: 25,
                bottom: 25,
                top: 40,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.8),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Row(
                children: [
                  if (widget.onBack != null) ...[
                    SizedBox(
                      height: 55,
                      width: 55,
                      child: ElevatedButton(
                        onPressed: widget.onBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6AA0),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                          side: const BorderSide(
                            color: Color(0xFF354372),
                            width: 1.0, 
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _buildSubmitButton(
                      () => _submitVote(
                        isProposalMode ? [_electionTitle] : positions,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalBody({bool includeButton = true}) {
    final String proposalTitle = _electionTitle;
    final String proposalDisplayTitle = _proposalDisplayName;

    final hasError = _showErrors && _selectedCandidates[proposalTitle] == null;

    return Column(
      children: [
        PositionVoteItem(
          positionTitle: proposalDisplayTitle,
          selectedCandidate: _selectedCandidates[proposalTitle],
          onSelectCandidate: () =>
              _handleSelectCandidate(proposalTitle, _getProposalOptions()),
          hasError: hasError,
          isProposal: true,
        ),
        if (includeButton) ...[
          const SizedBox(height: 50),
          _buildSubmitButton(() => _submitVote([proposalTitle])),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5C6AA0),
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        side: const BorderSide(
          color: Color(0xFF354372),
          width: 1.0, 
        ),
      ),
      child: const Text(
        'Submit Vote',
        style: TextStyle(
          color: Color(0xFFF8F8F8),
          fontSize: 14,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNotVerifiedCard() {
    double screenWidth = MediaQuery.of(context).size.width;
    double imageSize = (screenWidth * 0.60).clamp(150.0, 350.0);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: imageSize,
            height: imageSize,
            child: SvgPicture.asset(
              'assets/circle_unverif.svg',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Account not Verified",
            style: TextStyle(
              color: Color(0xFF404040),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "It seems like your semester has ended,\nPlease re-verify your account",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF747474),
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(uid: widget.uid),
                    ),
                  );
                },
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6AA0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Go to Profile settings",
                    style: TextStyle(
                      color: Color(0xFFF8F8F8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

