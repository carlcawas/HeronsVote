import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heronsvote/home/home.dart';
import 'sample_data.dart';
import 'announcement.dart';
import 'candidate_list.dart';
import 'propoasl_view.dart';
enum ContentView { candidates, proposals }

class CandidatesViewPage extends StatefulWidget {
  final String uid;
  const CandidatesViewPage({super.key, required this.uid});

  @override
  State<CandidatesViewPage> createState() => _CandidatesViewPageState();
}

class _CandidatesViewPageState extends State<CandidatesViewPage> {
  ContentView _selectedView = ContentView.candidates;
  int _selectedIndex = 1;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Candidates",
                    style: TextStyle(
                      color: Color(0xFF414141),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                milliseconds: 0,
                              ),
                              pageBuilder: (_, __, ___) => AnnouncementsPage(userId: widget.uid),
                            ),
                          ); //GOTO : ANNOUNCMENT WITH UID
                        },
                        icon: Container(
                          width: 45,
                          height: 45,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/announcement.svg',
                              color: const Color(0xFF404040),
                              width: 20,
                              height: 21,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                milliseconds: 0,
                              ),
                              pageBuilder: (_, __, ___) => AnnouncementsPage(userId: widget.uid),
                            ),
                          ); //GOTO ACCOUNT 
                        },
                        icon: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/account.svg',
                              color: const Color(0xFF404040),
                              width: 20,
                              height: 21,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _buildSegmentedControl(),

            const SizedBox(height: 22),

            Expanded(
              child: _selectedView == ContentView.candidates
                  ? _buildCandidatesList()
                  : _buildProposalsList(),
            ),
          ],
        ),
      ),

      //bottom nav
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF354372),
          unselectedItemColor: const Color(0xFF888888),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(uid: widget.uid),
                  ),
                );
              }
            });
          },
          currentIndex: _selectedIndex,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon('home', 0),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon('slate', 1),
              label: "Slates",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon('voting', 2),
              label: "Vote",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon('analytics', 3),
              label: "Analytics",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(String iconName, int index) {
    final bool isActive = _selectedIndex == index;
    final String assetPath =
        'assets/bottom_nav/${iconName}_${isActive ? 'active' : 'inactive'}.svg';
    return SvgPicture.asset(assetPath, width: 21, height: 19);
  }

  Widget _buildSegmentedControl() {
    const double outerRadius = 15.0;

    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(outerRadius),
        ),
        child: Row(
          children: [
            _buildSegment('Candidates', ContentView.candidates),
            _buildSegment('Proposals', ContentView.proposals),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String title, ContentView view) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = view;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5C6AA0) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFECECEC)
                  : const Color(0xFF404040),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              fontFamily: 'Geist',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
  //builder ng widget ng candidate row
  Widget _buildCandidatesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      itemCount: placeholderPositions.length,
      itemBuilder: (context, index) {
        return PositionListItem(position: placeholderPositions[index]);
      },
    );
  }
 //builder proposal
  Widget _buildProposalsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
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
      padding: const EdgeInsets.only(bottom: 15,),
      child: GestureDetector( 
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CandidateListPage(positionTitle: position.title, allSlates: placeholderSlates),
            ),
          );
        },
        child: Container(
          height: 70,
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
                  width: 53,
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
      padding: const EdgeInsets.only(bottom: 15),
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
          height: 70,
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
                  width: 53,
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