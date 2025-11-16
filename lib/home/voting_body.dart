// voting_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'sample_data.dart';
import 'candidate_selection.dart';

// =================================================================================
// 1. HELPER WIDGETS
// =================================================================================

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
          border: Border.all(color: const Color(0xFFE7E8E9), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Choose your candidate',
              style: TextStyle(
                color: const Color(0xFF404040),
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

// Candidate vote card (selected candidate)
class CandidateVoteCard extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback onTap;

  const CandidateVoteCard({
    super.key,
    required this.candidate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            // Image Placeholder
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7E8E9),
                borderRadius: BorderRadius.circular(50),
              ),
            ),

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
                  const SizedBox(height: 2),
                  Text(
                    candidate.partylist,
                    style: TextStyle(
                      color: const Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),

            // Year/College and Arrow Button
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${candidate.year} Year',
                  style: TextStyle(
                    color: const Color(0xFF747474),
                    fontSize: 12,
                    fontFamily: 'Geist',
                  ),
                ),
                Text(
                  candidate.college,
                  style: TextStyle(
                    color: const Color(0xFF747474),
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

// PositionVoteItem with error state
class PositionVoteItem extends StatelessWidget {
  final String positionTitle;
  final Candidate? selectedCandidate;
  final VoidCallback onSelectCandidate;
  final bool hasError;

  const PositionVoteItem({
    super.key,
    required this.positionTitle,
    this.selectedCandidate,
    required this.onSelectCandidate,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Expanded(
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
              if (hasError)
                Row(
                  children: [
                  Text(
                    'No Chosen Candidate',
                    style: TextStyle(
                      color: const Color(0xFFED6C6A),
                      fontSize: 12,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(width: 6,),
                  SvgPicture.asset(
                    'assets/error.svg',
                    height: 20,
                    width: 20,
                  )
                  ],
                ),
            ],
          ),
        ),
        // Show selected candidate or choose card
        selectedCandidate == null
            ? ChooseCandidateCard(onTap: onSelectCandidate)
            : CandidateVoteCard(
                candidate: selectedCandidate!,
                onTap: onSelectCandidate,
              ),
      ],
    );
  }
}

//VOTING PAGE

class VotingHomePage extends StatefulWidget {
  final String uid;

  const VotingHomePage({super.key, required this.uid});

  @override
  State<VotingHomePage> createState() => _VotingHomePageState();
}

class _VotingHomePageState extends State<VotingHomePage> {
  final Map<String, Candidate?> _selectedCandidates = {};
  bool _showErrors = false;

  // Hardcoded info for the header card
  final String _electionTitle = 'College Student Council Election';
  final String _electionPeriod = '(S.Y. 2025-2026)';

  List<String> get _positions {
    final allPositions = placeholderSlates
        .expand((slate) => slate.candidates)
        .map((candidate) => candidate.role)
        .toSet()
        .toList();

    // Sort positions in a logical order
    final positionOrder = [
      'Chairperson',
      'Vice Chairperson',
      'Secretary',
      'Treasurer',
      'Auditor',
    ];

    allPositions.sort((a, b) {
      final indexA = positionOrder.indexOf(a);
      final indexB = positionOrder.indexOf(b);
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return a.compareTo(b);
    });

    return allPositions;
  }

  // Get candidates for a specific position
  List<Candidate> _getCandidatesForPosition(String position) {
    return placeholderSlates
        .expand((slate) => slate.candidates)
        .where((candidate) => candidate.role == position)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Initialize all positions with no selection
    for (var position in _positions) {
      _selectedCandidates[position] = null;
    }
  }

  void _handleSelectCandidate(String positionTitle) async {
    // Navigate to CandidateSelectionPage and wait for result
    final Candidate? selectedCandidate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidateSelectionPage(
          positionTitle: positionTitle,
          candidates: _getCandidatesForPosition(positionTitle),
          initialSelection: _selectedCandidates[positionTitle],
        ),
      ),
    );

    if (selectedCandidate != null && mounted) {
      setState(() {
        _selectedCandidates[positionTitle] = selectedCandidate;
        // Hide errors when user selects a candidate
        _showErrors = false;
      });
    }
  }

  void _submitVote() {
    // Check if all positions have been voted for
    final hasEmptyPositions = _selectedCandidates.values.any(
      (candidate) => candidate == null,
    );

    if (hasEmptyPositions) {
      setState(() {
        _showErrors = true;
      });

      // Count empty positions
      final emptyPositions = _positions
          .where((position) => _selectedCandidates[position] == null)
          .toList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please select candidates for all positions!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Missing: ${emptyPositions.join(', ')}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If complete - show success
    final selectedNames = _selectedCandidates.entries
        .map((entry) => '${entry.key}: ${entry.value!.name}')
        .join('\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votes submitted successfully!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your selections:\n$selectedNames',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Election Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 12),
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
                      Text(
                        _electionTitle,
                        style: const TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 24,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _electionPeriod,
                        style: TextStyle(
                          color: const Color(0xFF747474),
                          fontSize: 16,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                          Text(
                            'Ongoing',
                            style: TextStyle(
                              color: const Color(0xFF747474),
                              fontSize: 14,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // List of PositionVoteItems with error states
                ..._positions.map((positionTitle) {
                  final hasError =
                      _showErrors && _selectedCandidates[positionTitle] == null;

                  return PositionVoteItem(
                    positionTitle: positionTitle,
                    selectedCandidate: _selectedCandidates[positionTitle],
                    onSelectCandidate: () =>
                        _handleSelectCandidate(positionTitle),
                    hasError: hasError,
                  );
                }).toList(),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // "Submit Vote" button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _submitVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6AA0),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
