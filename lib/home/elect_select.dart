import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';

class ElectionSelectionPage extends StatefulWidget {
  final String uid;
  final List<Map<String, dynamic>> activeElections;
  final Function(Map<String, dynamic>) onElectionSelected;

  const ElectionSelectionPage({
    super.key,
    required this.uid,
    required this.activeElections,
    required this.onElectionSelected,
  });

  @override
  State<ElectionSelectionPage> createState() => _ElectionSelectionPageState();
}

class _ElectionSelectionPageState extends State<ElectionSelectionPage> {
  bool _isVerified = true;
  bool _allVoted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

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
      if (userDoc.exists && mounted) {
        setState(() {
          _isVerified = userDoc.data()?['isVerified'] ?? false;
          _allVoted = widget.activeElections.isNotEmpty && votedCount == widget.activeElections.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }
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
        body: _buildNotVerifiedCard(),
      );
    }
    if (_allVoted) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: VotingCompletePageBody()), 
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Election',
                      style: TextStyle(
                        color: Color(0xFF404040),
                        fontSize: 20,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${widget.activeElections.length} active elections.\nPlease select one to continue.',
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

              const SizedBox(height: 30),

              const Text(
                'Active Election',
                style: TextStyle(
                  color: Color(0xFF404040),
                  fontSize: 14,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              //list election
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
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

                      return FutureBuilder<bool>(
                        future: _hasUserVoted(electionId, type),
                        builder: (context, snapshot) {
                          final bool hasVoted = snapshot.data ?? false;
                          final bool isChecking =
                              snapshot.connectionState == ConnectionState.waiting;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (hasVoted || isChecking)
                                  ? null
                                  : () {
                                      widget.onElectionSelected(election);
                                    },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 24),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        election['title'] ?? 'Election',
                                        style: TextStyle(
                                          // Grey out text if voted
                                          color: hasVoted
                                              ? Colors.grey
                                              : const Color(0xFF404040),
                                          fontSize: 16,
                                          fontFamily: 'Geist',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (hasVoted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFBBEDBB),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "Voted",
                                          style: TextStyle(
                                            color: Color(0xFF76D675),
                                            fontSize: 12,
                                            fontFamily: 'Geist',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 50),
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