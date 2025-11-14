import 'package:flutter/material.dart';
import 'dart:async';
import 'announcement.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'slates_list.dart';
import 'elected_official_page.dart';
import 'candidates_view_page.dart';
// TODO: import screens for different redirection

class HomeScreen extends StatefulWidget {
  final String? uid;
  const HomeScreen({super.key, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late final String? _userId;

  int _selectedIndex = 0;
  Timer? _timer;
  DateTime? currentBackPressTime;

  // Page controllers for sliders
  final PageController _activeItemsPageController = PageController();
  int _currentActiveItemPage = 0;

  final PageController _slatesPageController = PageController();
  int _currentSlatesPage = 0;

  // hold all active elections, proposals for the top slider/box
  List<Map<String, dynamic>> _activeItems = [];
  // hold the single most recent ended election (if within a week)
  List<Map<String, dynamic>> _recentlyEndedItems = [];
  // Combined list for the top slider
  List<Map<String, dynamic>> _sliderItems = [];

  // fetched from db user collection
  String _userName = "User";
  String _userCollegeId = "";
  String _userCollegeAbbreviation = "";
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.uid;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _activeItemsPageController.dispose();
    _slatesPageController.dispose();
    super.dispose();
  }

  // 2 backs swipe to exit app function
  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit app'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
      return false;
    }
    return true;
  }

  // checks if an ended election is recent. checks if it ended in the past and is within 7 days
  bool _isRecentlyEnded(Timestamp endTimestamp) {
    final int days = 7;
    final endDate = endTimestamp.toDate();
    final now = DateTime.now();
    return now.isAfter(endDate) && now.difference(endDate).inDays <= days;
  }

  // formats the data/information fetched from a db fetch/snapshot
  Map<String, dynamic> _docToMap(DocumentSnapshot doc) {
    return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
  }

  // format election types to string
  String _formatType(String type) {
    switch (type) {
      case 'college':
        return 'College Election';
      case 'university':
        return 'University Election';
      case 'proposal':
        return 'University Proposal Election';
      default:
        return 'Event';
    }
  }

  // prioritizes election cards
  int _getPriority(String type) {
    switch (type) {
      case 'university':
        return 1; // 1st priority
      case 'college':
        return 2; // 2nd priority
      case 'proposal':
        return 3; // 3rd priority
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: Text('Error: User ID not found.'));
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _firebaseService.getUserStream(_userId),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // Process backend part
              // Fetch user data from db
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              // takes only the 1st name to avoid overflow
              final String fullName = userData['name'] ?? 'User';
              if (fullName.trim().isEmpty) {
                _userName = 'User';
              } else {
                _userName = fullName.split(' ').first;
              }
              _userCollegeId = userData['college_id'] ?? '';
              _userCollegeAbbreviation = userData['college_id'] ?? '';
              _isVerified = userData['isVerified'] ?? false;
              // Combine Streams for all active/ended items
              return StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.getActiveCollegeElectionStream(
                  _userCollegeId,
                ),
                builder: (context, collegeElecSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService
                        .getActiveUniversityElectionStream(),
                    builder: (context, uniElecSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: _firebaseService
                            .getActiveUniversityProposalStream(),
                        builder: (context, proposalSnap) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: _firebaseService
                                .getRecentlyEndedCollegeElection(
                                  _userCollegeId,
                                ),
                            builder: (context, endedCollegeSnap) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: _firebaseService
                                    .getRecentlyEndedUniversityElection(),
                                builder: (context, endedUniSnap) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: _firebaseService
                                        .getRecentlyEndedUniversityProposal(),
                                    builder: (context, endedProposalSnap) {
                                      if (!collegeElecSnap.hasData ||
                                          !uniElecSnap.hasData ||
                                          !proposalSnap.hasData ||
                                          !endedCollegeSnap.hasData ||
                                          !endedUniSnap.hasData ||
                                          !endedProposalSnap.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      // Clear previous active items
                                      _activeItems = [];
                                      _recentlyEndedItems = [];

                                      // Check for active items
                                      if (collegeElecSnap
                                          .data!
                                          .docs
                                          .isNotEmpty) {
                                        _activeItems.add({
                                          'type': 'college',
                                          'ongoing': true,
                                          ..._docToMap(
                                            collegeElecSnap.data!.docs.first,
                                          ),
                                        });
                                      }
                                      if (uniElecSnap.data!.docs.isNotEmpty) {
                                        _activeItems.add({
                                          'type': 'university',
                                          'ongoing': true,
                                          ..._docToMap(
                                            uniElecSnap.data!.docs.first,
                                          ),
                                        });
                                      }
                                      if (proposalSnap.data!.docs.isNotEmpty) {
                                        _activeItems.add({
                                          'type': 'proposal',
                                          'ongoing': true,
                                          ..._docToMap(
                                            proposalSnap.data!.docs.first,
                                          ),
                                        });
                                      }

                                      // Always check for recently ended items
                                      if (endedCollegeSnap
                                          .data!
                                          .docs
                                          .isNotEmpty) {
                                        final doc =
                                            endedCollegeSnap.data!.docs.first;
                                        if (_isRecentlyEnded(
                                          doc['end'] as Timestamp,
                                        )) {
                                          _recentlyEndedItems.add({
                                            'type': 'college',
                                            'ongoing': false,
                                            ..._docToMap(doc),
                                          });
                                        }
                                      }
                                      if (endedUniSnap.data!.docs.isNotEmpty) {
                                        final doc =
                                            endedUniSnap.data!.docs.first;
                                        if (_isRecentlyEnded(
                                          doc['end'] as Timestamp,
                                        )) {
                                          _recentlyEndedItems.add({
                                            'type': 'university',
                                            'ongoing': false,
                                            ..._docToMap(doc),
                                          });
                                        }
                                      }
                                      if (endedProposalSnap
                                          .data!
                                          .docs
                                          .isNotEmpty) {
                                        final doc =
                                            endedProposalSnap.data!.docs.first;
                                        if (_isRecentlyEnded(
                                          doc['end'] as Timestamp,
                                        )) {
                                          _recentlyEndedItems.add({
                                            'type': 'proposal',
                                            'ongoing': false,
                                            ..._docToMap(doc),
                                          });
                                        }
                                      }

                                      // Sort recently ended items
                                      _recentlyEndedItems.sort(
                                        (a, b) => (b['end'] as Timestamp)
                                            .compareTo(a['end'] as Timestamp),
                                      );

                                      // Create the combined list
                                      _sliderItems = [
                                        ..._activeItems,
                                        ..._recentlyEndedItems,
                                      ];

                                      // Sort election cards based on priority
                                      _sliderItems.sort(
                                        (a, b) => _getPriority(
                                          a['type'],
                                        ).compareTo(_getPriority(b['type'])),
                                      );

                                      // Update bounds check for new list
                                      if (_currentActiveItemPage >=
                                          _sliderItems.length) {
                                        _currentActiveItemPage = 0;
                                        if (_activeItemsPageController
                                            .hasClients) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (_activeItemsPageController
                                                    .hasClients) {
                                                  _activeItemsPageController
                                                      .jumpToPage(0);
                                                }
                                              });
                                        }
                                      }

                                      // For UI update and building
                                      return SingleChildScrollView(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 25,
                                          vertical: 20,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // Header: Hello, name
                                                Text(
                                                  "Hello, $_userName",
                                                  style: const TextStyle(
                                                    color: Color(0xFF414141),
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Geist',
                                                  ),
                                                ),
                                                // Header: Notification & Account btn
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () {
                                                        //TODO: ANNOUNCEMENT REDIRECTION
                                                        print("Going to AnnouncementsPage with userId: $_userId"); //debugging
                                                        Navigator.push(
                                                          context,
                                                          PageRouteBuilder(
                                                            transitionDuration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      0,
                                                                ),
                                                            
                                                            pageBuilder: (_, __, ___) => AnnouncementsPage(userId: _userId),
                                                          ),
                                                        );
                                                      },
                                                      icon: SvgPicture.asset(
                                                        'assets/announcement.svg',
                                                        color: Color(
                                                          0xFF404040,
                                                        ),
                                                        width: 20,
                                                        height: 25,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        //TODO: ACCOUNT REDIRECTION
                                                      },
                                                      icon: SvgPicture.asset(
                                                        'assets/account.svg',
                                                        color: const Color(
                                                          0xFF404040,
                                                        ),
                                                        width: 21,
                                                        height: 23,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 30),

                                            // 'Not Verified' message shows if user not verified
                                            if (!_isVerified) ...[
                                              _buildNotVerifiedWarningCard(),
                                              const SizedBox(height: 30),
                                            ],

                                            // call election cards
                                            _buildSliderOrNoElectionCard(),
                                            const SizedBox(height: 30),

                                            // Officials/Slates card
                                            _buildConditionalSecondSection(),

                                            // 'Before you vote' card
                                            const Text(
                                              "Before you vote",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF404040),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                // TODO: ADD REDIRECT FUNCTIONS
                                                _buildInfoCard("Voting rules"),
                                                const SizedBox(width: 22.7),
                                                _buildInfoCard(
                                                  "Voting process",
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 40),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),

        // Bottom navigation
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
               if(index == 0){
                setState(() {
                  _selectedIndex = index;
                });
               }

               switch(index){
                case 0:
                       break;
                case 1:
                    Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => CandidatesViewPage(uid: widget.uid),),);
               }
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
      ),
    );
  }

  //nav area builder
  Widget _buildNavIcon(String iconName, int index) {
    final bool isActive = _selectedIndex == index;
    final String assetPath =
        'assets/bottom_nav/${iconName}_${isActive ? 'active' : 'inactive'}.svg';
    return SvgPicture.asset(assetPath, width: 21, height: 19);
  }

  // Decides to show slider or "No Election" card
  Widget _buildSliderOrNoElectionCard() {
    if (_sliderItems.isEmpty) {
      return _buildNoElectionCard();
    } else {
      // Pass the combined list to the slider
      return _buildActiveItemsSliderCard(_sliderItems);
    }
  }

  // No Election state card
  Widget _buildNoElectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 30, left: 28, bottom: 30, right: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF354372),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                // fetch from user data
                _userCollegeAbbreviation,
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "No active election. Check Announcements\nfor updates.",
            style: TextStyle(
              color: Color(0xFFD9D9D9),
              fontSize: 12,
              height: 20 / 12,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6AA0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                //TODO: Navigate to election info or announcements
              },
              child: const Text(
                "Announcements",
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF8F8F8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // builds the slider shell
  Widget _buildActiveItemsSliderCard(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _activeItemsPageController,
            itemCount: items.length,
            onPageChanged: (page) {
              setState(() {
                _currentActiveItemPage = page;
              });
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildSliderItemCard(item);
            },
          ),
          if (items.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentActiveItemPage
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Unified card for both Ongoing and Ended elections
  Widget _buildSliderItemCard(Map<String, dynamic> item) {
    final String type = item['type'] ?? '';
    final bool isOngoing = item['ongoing'] ?? false;

    // sets the text to "UMak" for university election OR proposal on the card
    final String title;
    if (type == 'university' || type == 'proposal') {
      title = 'UMak';
    } else {
      title = _userCollegeAbbreviation;
    }

    // Formatted type
    final String subtitle = _formatType(type);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.only(top: 30, left: 28, bottom: 30, right: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF354372),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFF8F8F8),
                    fontSize: 12,
                    fontFamily: 'Geist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Timer or Ended Button
          if (isOngoing) ...[
            // Show timer
            Builder(
              builder: (context) {
                final Timestamp endTimestamp = item['end'];
                final DateTime endTime = endTimestamp.toDate();
                final Duration timeLeft = endTime.difference(DateTime.now());
                return _buildTimerSection(
                  timeLeft.isNegative ? Duration.zero : timeLeft,
                );
              },
            ),
          ] else ...[
            // Show "Ended" text and "View Result" button
            const Text(
              "Election ended:",
              style: TextStyle(color: Color(0xFFD9D9D9), fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 47,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6AA0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Redirect function
                onPressed: () {
                  final String id = item['id'];
                  final String itemType = item['type'];
                  // TODO: Navigate to Results Screen
                  // Example:
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => ResultsScreen(id: id, type: itemType),
                  // ));
                  print("Navigate to results for ID: $id, Type: $itemType");
                },
                child: const Text(
                  "View Result",
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF8F8F8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionalSecondSection() {
    // If no elections in the slider (idle mode), show current college officials as a default.
    if (_sliderItems.isEmpty) {
      return _buildCurrentOfficialsSection(
        "Current $_userCollegeId Officials",
        _firebaseService.getCurrentOfficialsStream(_userCollegeId),
      );
    }

    // Get the item currently visible in the slider
    final currentItem = _sliderItems[_currentActiveItemPage];
    final String type = currentItem['type'];
    final String id = currentItem['id'];
    final bool isOngoing = currentItem['ongoing'];

    // If it's a proposal (ongoing or ended), show uni officials
    if (type == 'proposal') {
      return _buildCurrentOfficialsSection(
        "University Officials",
        _firebaseService.getUniversityOfficialsStream(),
      );
    }

    // Item is an ELECTION (College or University)
    if (isOngoing) {
      // Show Slates for ongoing elections
      return _buildSlatesSection(id);
    } else {
      // Show Results for ended elections
      return _buildCurrentOfficialsSection(
        "Newly Elected Officials",
        _firebaseService.getElectionResultsStream(id),
        isResults: true,
      );
    }
  }

  // builds the "Current Officials" or "Newly Elected" slider
  Widget _buildCurrentOfficialsSection(
    String title,
    Stream<QuerySnapshot> stream, {
    bool isResults = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF404040),
              ),
            ),
            GestureDetector(
              onTap: () {
                //TODO: Navigate to officials
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ElectedOfficialsPage(),
                ),
              );
              },
              child: const Text(
                "See all",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF404040),
                  fontFamily: 'Geist',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            // Error handling
            if (snapshot.hasError) {
              print("Error loading officials: ${snapshot.error}");
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: Text("Error: Could not load officials."),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: Text("No ${isResults ? 'results' : 'officials'} found."),
              );
            }

            final officials = snapshot.data!.docs;

            return _OfficialsPageView(
              officials: officials,
              isResults: isResults,
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSlatesSection(String electionId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Slates",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF404040),
              ),
            ),
            GestureDetector(
              onTap: () {
                //TODO: Slates
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SlateListPage(electionId: electionId), 
                ),
              );
              },
              child: const Text(
                "See all",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF404040),
                  fontFamily: 'Geist',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        // StreamBuilder for Slates
        StreamBuilder<QuerySnapshot>(
          stream: _firebaseService.getSlatesStream(electionId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print("Error loading slates: ${snapshot.error}");
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: Text("Error: Could not load slates."),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              // Hide section if no slates
              return const SizedBox.shrink();
            }

            final slates = snapshot.data!.docs;

            return Column(
              children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _slatesPageController,
                        itemCount: slates.length,
                        onPageChanged: (int page) {
                          setState(() {
                            _currentSlatesPage = page;
                          });
                        },
                        itemBuilder: (context, index) {
                          final slate =
                              slates[index].data() as Map<String, dynamic>;
                          final String name = slate['name'] ?? 'Unnamed Slate';
                          final String description =
                              slate['slogan'] ?? 'No description.';

                          // TODO: Replace with field from Firestore
                          // e.g., final String imageUrl = slate['imageUrl'];
                          final String imageUrl =
                              slate['imageUrl'] ??
                              'https://placehold.co/600x400/354372/FFFFFF?text=${name.replaceAll(' ', '+')}';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            clipBehavior: Clip.antiAlias, // Clips the image
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                                // Handle image loading errors
                                onError: (exception, stackTrace) {
                                  print('Error loading image: $exception');
                                },
                              ),
                            ),
                            child: Container(
                              // Gradient overlay for text readability
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.black.withOpacity(0.0),
                                  ],
                                  stops: [0.0, 0.5],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Dots for sliders
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            slates.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentSlatesPage
                                    ? Colors
                                          .white // Active dot
                                    : Colors.white.withOpacity(
                                        0.5,
                                      ), // Inactive dot
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // Timer Build
  Widget _buildTimerSection(Duration timeLeft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Days left until election closes:",
          style: TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 12,
            height: 20 / 12,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildTimeBox(
                timeLeft.inDays.toString().padLeft(2, '0'),
                "Days",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeBox(
                (timeLeft.inHours % 24).toString().padLeft(2, '0'),
                "Hours",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeBox(
                (timeLeft.inMinutes % 60).toString().padLeft(2, '0'),
                "Minutes",
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Each box inside the timer box
  Widget _buildTimeBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.only(top: 7, bottom: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF5C6AA0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFECECEC),
              fontSize: 20,
              height: 20 / 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFECECEC),
              fontSize: 12,
              height: 20 / 12,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  // Info card
  Widget _buildInfoCard(String title) {
    return Expanded(
      child: Container(
        height: 97,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Color(0xFF5C6AA0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF354372)),
          boxShadow: [
            // Outer shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            // Inner shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF8F8F8),
            ),
          ),
        ),
      ),
    );
  }

  // Not verified card, only shows if not field 'isVerified' == false
  Widget _buildNotVerifiedWarningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 30, left: 28, bottom: 30, right: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF354372),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account not Verified",
            style: TextStyle(
              color: Color(0xFFF8F8F8),
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "It seems like your semester has ended,\nPlease re-verify your account",
            style: TextStyle(
              color: Color(0xFFD9D9D9),
              fontSize: 14,
              fontFamily: 'Geist',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6AA0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                //TODO: Navigate to profile settings
              },
              child: const Text(
                "Go to Profile settings",
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// used for "Current Officials" and "Newly Elected"
class _OfficialsPageView extends StatefulWidget {
  final List<DocumentSnapshot> officials;
  final bool isResults;

  const _OfficialsPageView({required this.officials, this.isResults = false});

  @override
  State<_OfficialsPageView> createState() => _OfficialsPageViewState();
}

class _OfficialsPageViewState extends State<_OfficialsPageView> {
  // Each instance of this widget manages its own controller and page
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController, // Use local controller
                itemCount: widget.officials.length,
                onPageChanged: (int page) {
                  setState(() {
                    // Use local setState
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final officialDoc =
                      widget.officials[index].data() as Map<String, dynamic>;
                  // Fields will be different for results vs officials
                  final String name = officialDoc['name'] ?? 'Unknown';
                  final String position = officialDoc['position'] ?? 'Unknown';

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isResults)
                          // Winner badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF5C6AA0,
                                  ).withOpacity(0.1),
                                  border: Border.all(
                                    color: const Color(0xFF5C6AA0),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 35,
                                  color: Color(0xFF5C6AA0),
                                ),
                              ),
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromARGB(255, 0, 47, 90),
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          // Profile placeholder
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414141),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          position,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Dots overlay
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.officials.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? const Color(0xFF354372) // Active dot
                            : const Color(0xFFD9D9D9), // Inactive dot
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
