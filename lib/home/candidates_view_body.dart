import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'sample_data.dart';
import 'announcement.dart';
import 'candidate_list.dart';
import 'propoasl_view.dart';

enum ContentView { candidates, proposals }

class CandidatesViewBody extends StatefulWidget {
  final String uid;
  const CandidatesViewBody({super.key, required this.uid});

  @override
  State<CandidatesViewBody> createState() => _CandidatesViewBodyState();
}

class _CandidatesViewBodyState extends State<CandidatesViewBody> {
  ContentView _selectedView = ContentView.candidates;

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Column(
        children: [

          // 4. --- ADDED PADDING ---
          // Add padding here to account for the removed header
          const SizedBox(height: 4), // gap ni segmented sa appbar 16 sa figma

          _buildSegmentedControl(),

          const SizedBox(height: 8), // gap ni segmented sa list 22 yung sa figma

          Expanded(
            // --- 1. ADDED ANIMATEDSWITCHER ---
            // This will smoothly fade between the two lists
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                // Use a FadeTransition
                return FadeTransition(opacity: animation, child: child);
              },
              child: _selectedView == ContentView.candidates
                  // We add a Key so the AnimatedSwitcher knows which child is which
                  ? _buildCandidatesList(key: const ValueKey('candidates_list'))
                  : _buildProposalsList(key: const ValueKey('proposals_list')),
            ),
          ),
        ],
      ),
    );

  }

  // --- 1. UPDATED SEGMENTED CONTROL TO USE STACK AND ANIMATEDPOSITIONED ---
  Widget _buildSegmentedControl() {
    const double outerRadius = 15;
    const double innerRadius = 11;
    const double innerPadding = 4;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      // LayoutBuilder gives us the constraints to calculate width
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate the width of one tab
          final double tabWidth = (constraints.maxWidth - (innerPadding * 2)) / 2;

          return Container(
            height: 36,
            padding: const EdgeInsets.all(innerPadding), // 4px padding
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7), // Light grey background
              borderRadius: BorderRadius.circular(outerRadius),
            ),
            child: Stack(
              children: [
                // This is the sliding blue background
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  // Ternary operator to slide left or right
                  left: _selectedView == ContentView.candidates ? 0 : tabWidth,
                  right: _selectedView == ContentView.proposals ? 0 : tabWidth,
                  child: Container(
                    height: 36 - (innerPadding * 2), // Full height minus padding
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6AA0), // Blue color
                      borderRadius: BorderRadius.circular(innerRadius),
                    ),
                  ),
                ),
                
                // This Row holds the text labels and gesture detectors
                Row(
                  children: [
                    _buildSegment('Candidates', ContentView.candidates),
                    _buildSegment('Proposals', ContentView.proposals),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // --- 2. UPDATED SEGMENT WIDGET ---
  Widget _buildSegment(String title, ContentView view) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = view;
          });
        },
        // sliding blue part behind it
        child: Container(
          alignment: Alignment.center,
          color: Colors.transparent, // Transparent background
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            style: TextStyle(
              // The text color still animates
              color: isSelected
                  ? const Color(0xFFECECEC) // White when selected
                  : const Color(0xFF404040), // Dark when not
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              fontFamily: 'Geist',
              fontSize: 14,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }
  
  //builder ng widget ng candidate row
  // --- 4. ADDED Key PARAMETER ---
  Widget _buildCandidatesList({Key? key}) {
    return ListView.builder(
      key: key, // Pass the key to the ListView
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      itemCount: placeholderPositions.length,
      itemBuilder: (context, index) {
        return PositionListItem(position: placeholderPositions[index]);
      },
    );
  }

  //builder proposal
  // --- 4. ADDED Key PARAMETER ---
  Widget _buildProposalsList({Key? key}) {
    return ListView.builder(
      key: key, // Pass the key to the ListView
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      itemCount: placeholderProposals.length,
      itemBuilder: (context, index) {
        return ProposalListItem(proposal: placeholderProposals[index]);
      },
    );
  }
}

// --- Position Candidates
class PositionListItem extends StatelessWidget {
  final Position position;
  final VoidCallback? onTap;
  const PositionListItem({super.key, required this.position, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CandidateListPage(
                  positionTitle: position.title,
                  allSlates: placeholderSlates),
            ),
          );
        },
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              right: 10,
              top: 10,
              bottom: 10,
              left: 26,
            ),
            child: Row(
              children: [
                // Position Title
                Expanded(
                  child: Text(
                    position.title,
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 16,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Right arrow button
                Container(
                  width: 45,
                  height: 45,
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
        ),
      ),
    );
  }
}

// --- Proposal List Item
class ProposalListItem extends StatelessWidget {
  final Proposal proposal;
  const ProposalListItem({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProposalViewPage(proposal: proposal),
            ),
          );
        },
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              right: 10,
              top: 10,
              bottom: 10,
              left: 26,
            ),
            child: Row(
              children: [
                // proposal Title
                Expanded(
                  child: Text(
                    proposal.title,
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 16,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Right arrow button
                Container(
                  width: 45,
                  height: 45,
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
        ),
      ),
    );
  }
}