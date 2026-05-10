import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'election_history.dart';

class ElectionSelectionPage extends StatefulWidget {
  final String uid;
  final List<Map<String, dynamic>> activeElections; // Or 'elections'
  final Function(Map<String, dynamic>) onElectionSelected;
  final Future<void> Function()? onRefresh;
  
  // 1. ADD THIS FLAG
  final bool isResultMode; 

  const ElectionSelectionPage({
    super.key,
    required this.uid,
    required this.activeElections,
    required this.onElectionSelected,
    this.onRefresh,
    this.isResultMode = false, // Default is false (Voting Mode)
  });

  @override
  State<ElectionSelectionPage> createState() => _ElectionSelectionPageState();
}

class _ElectionSelectionPageState extends State<ElectionSelectionPage> {
  bool _isVerified = true;
  bool _isLoading = true;
  bool _allVoted = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      // 1. Check Verification (Always needed for security)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      bool verified = true;
      if (userDoc.exists) {
        verified = userDoc.data()?['isVerified'] ?? false;
      }

      // 2. CHECK MODE: If isResultMode, SKIP vote checking logic
      if (widget.isResultMode) {
        if (mounted) {
          setState(() {
            _isVerified = verified;
            _allVoted = false; // Never show "Voting Complete" screen in Results
            _isLoading = false;
          });
        }
        return; // EXIT EARLY
      }

      // --- VOTING MODE LOGIC (Only runs if !isResultMode) ---
      int votedCount = 0;
      if (widget.activeElections.isNotEmpty) {
        for (var election in widget.activeElections) {
          final String id = election['id'];
          final String type = election['type'] ?? 'election';
          final hasVoted = await _hasUserVoted(id, type);
          if (hasVoted) {
            votedCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isVerified = verified;
          _allVoted = widget.activeElections.isNotEmpty && 
                      votedCount == widget.activeElections.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error checking status: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper (unchanged)
  Future<bool> _hasUserVoted(String electionId, String type) async {
    try {
      final collection = (type == 'proposal') ? 'proposals' : 'elections';
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(electionId)
          .collection('votes')
          .doc(widget.uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isVerified) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildNotVerifiedCard(), // Assuming this is defined in your file
      );
    }

    // Keep showing the election list even if all active elections were already voted.
    // This lets users still see ongoing items and their voted/locked state.

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh ?? () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
              
              // HEADER CARD
              if (widget.isResultMode || widget.activeElections.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(15),
                    // Removed shadow as per your previous code style if needed
                    border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Change Title based on Mode
                        widget.isResultMode ? 'View Results' : 'Choose Election',
                        style: const TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 20,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isResultMode
                            ? 'Select an election to view the live or\npublished results.'
                            : 'You have ${widget.activeElections.length} active elections.\nPlease select one to continue.',
                        style: const TextStyle(
                          color: Color(0xFF747474),
                          fontSize: 14,
                          fontFamily: 'Geist',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

              // const SizedBox(height: 30),

              if (widget.activeElections.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 15.0),
                  child: Text(
                    widget.isResultMode ? 'All Elections' : 'Active Election',
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 14,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // LIST CONTAINER
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: widget.activeElections.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE5E5E5),
                        indent: 20,
                        endIndent: 20,
                      ),
                      itemBuilder: (context, index) {
                        final election = widget.activeElections[index];
                        final String electionId = election['id'] ?? '';
                        final String type = election['type'] ?? 'election';

                        // IF RESULT MODE: Return clickable tile immediately (no DB check)
                        if (widget.isResultMode) {
                          return _buildListTile(
                            election: election,
                            isDisabled: false,
                            showVotedBadge: false,
                          );
                        }

                        // IF VOTING MODE: Check DB for vote status
                        return FutureBuilder<bool>(
                          future: _hasUserVoted(electionId, type),
                          builder: (context, snapshot) {
                            final bool hasVoted = snapshot.data ?? false;
                            final bool isChecking =
                                snapshot.connectionState == ConnectionState.waiting;

                            return _buildListTile(
                              election: election,
                              isDisabled: hasVoted || isChecking,
                              showVotedBadge: hasVoted,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ] else ...[
                if (!widget.isResultMode)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.58,
                    child: const Center(
                      child: Text(
                        'No elections available.',
                        style: TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 15,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 20),
              
              if (widget.isResultMode) ...[

                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                  child: const Text(
                  'Election History',
                  style: TextStyle(
                    color: Color(0xFF404040),
                    fontSize: 14,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ),
                const SizedBox(height: 2),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFD9D9D9),
                      width: 0.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ElectionHistoryPage(uid: widget.uid),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'View Election History',
                                style: TextStyle(
                                  color: Color(0xFF404040),
                                  fontSize: 16,
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Tile Helper to keep build clean
  Widget _buildListTile({
    required Map<String, dynamic> election, 
    required bool isDisabled, 
    required bool showVotedBadge
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                widget.onElectionSelected(election);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (election['type'] == 'proposal' ? election['proposalName'] : election['title']) ?? (election['type'] == 'proposal' ? 'Proposal Name' : 'Election'),
                  style: TextStyle(
                    // Grey out only if disabled in voting mode
                    color: isDisabled && showVotedBadge 
                        ? Colors.grey 
                        : const Color(0xFF404040),
                    fontSize: 16,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (showVotedBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBEDBB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Voted",
                    style: TextStyle(
                      color: Color(0xFF76D675),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // --- NEW: STATUS BADGE (Only in Result Mode) ---
              if (widget.isResultMode)
                _buildStatusBadge(election),
            ],
          ),
        ),
      ),
    );
  }

  //NOT VERIFIED
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
            mainAxisAlignment:MainAxisAlignment.center, 
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

  Widget _buildStatusBadge(Map<String, dynamic> election) {
    bool isEnded = false;
    try {
      final String status = (election['status'] ?? '').toString();
      final bool? ongoing = election['ongoing'] as bool?;

      // Priority: explicit status/ongoing fields.
      if (status == 'Closed' || ongoing == false) {
        isEnded = true;
      } else if (status == 'Ongoing' && ongoing == true) {
        isEnded = false;
      } else if (election['end'] != null) {
        // Fallback: infer from end date only if status fields are missing/ambiguous.
        DateTime end = (election['end'] as Timestamp).toDate();
        isEnded = DateTime.now().isAfter(end);
      }
    } catch (e) {
      isEnded = false;
    }

    final Color bgColor = isEnded 
        ? const Color(0xFFC3D9FF)
        : const Color(0xFFD6FBD5); 
        
    final Color textColor = isEnded 
        ? const Color(0xFF1F8EFF) 
        : const Color(0xFF76D675); 
        
    final String text = isEnded ? "Ended" : "Ongoing";

    //Return the Badge (Same style as your Voted badge)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Geist',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
class VotingCompletePageBody extends StatelessWidget {
  const VotingCompletePageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( 
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(20),
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
        ],
      ),
    );
  }
}

