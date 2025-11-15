import 'package:flutter/material.dart';
import 'dart:async';
import 'announcement.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'slates_list.dart';
import 'elected_official_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: import screens for different redirection

class HomeBody extends StatefulWidget {
  final String uid;
  const HomeBody({super.key, required this.uid});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final FirebaseService _firebaseService = FirebaseService();
  late final String _userId;

  Timer? _timer;

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

  // checks if an ended election is recent. checks if it ended in the past and is within 7 days
  bool _isRecentlyEnded(Timestamp endTimestamp) {
    final int days = 7;
    final endDate = endTimestamp.toDate();
    final now = DateTime.now();
    return now.isAfter(endDate) && now.difference(endDate).inDays <= days;
  }

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
        return 1;
      case 'college':
        return 2;
      case 'proposal':
        return 3;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    
    // NO Scaffold, NO WillPopScope, NO BottomNavigationBar
    // Start with the content.

    return StreamBuilder<DocumentSnapshot>(
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

        //may gantong code sa dati 
        /*final String fullName = userData['name'] ?? 'User';
              if (fullName.trim().isEmpty) {
                _userName = 'User';
              } else {
                _userName = fullName.split(' ').first;
              }*/
        
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

                                // This is your main page content
                                // For UI update and building
                                return SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(), //scroll only when needed
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24, //balik mo to 25 pag wala na margin lahat ng widget keyword:25marginback
                                    vertical: 0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [

                                      // The "Hello, name" header Row is GONE
                                      // It is now in the persistent AppBar in home.dart
                                      
                                      // 'Not Verified' message shows if user not verified
                                      if (!_isVerified) ...[
                                        _buildNotVerifiedWarningCard(),
                                        const SizedBox(height: 30),
                                      ],
                                      
                                      // call election cards
                                      _buildSliderOrNoElectionCard(),
                                      const SizedBox(height: 22), // gap ni ongoing slates and countdown card

                                      // Officials/Slates card
                                      _buildConditionalSecondSection(),

                                      // 'Before you vote' card
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: const Text(
                                          "Before you vote",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF404040),
                                          )
                                        ),
                                      ),
                                      
                                      
                                      const SizedBox(height: 16),//gap between title and respective btns
                                      Row(
                                        children: [
                                          // TODO: ADD REDIRECT FUNCTIONS

                                          _buildInfoCard("Voting rules"),
                                          const SizedBox(width: 22),
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
    );
  }

  // --- All your helper widgets belong here ---
  // (Paste ALL your other _build... methods and helper widgets here)
  
  Widget _buildNotVerifiedWarningCard() { // not verified card 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 28, bottom: 30, right: 28),
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
          const SizedBox(height: 12),
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
  } // not verified card end

  Widget _buildSliderOrNoElectionCard() {
    if (_sliderItems.isEmpty) {
      return _buildNoElectionCard();
    } else {
      return _buildActiveItemsSliderCard(_sliderItems);
    }
  }


  Widget _buildNoElectionCard() { //idle election card
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 28, bottom: 21, right: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF354372),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],

        border: Border.all(
          color: const Color(0xFF404040),
          width: 0.5,
        ),

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
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
          const SizedBox(height: 12),
          const Text(
            "No active election. Check Announcements\nfor updates.",
            style: TextStyle(
              color: Color(0xFFD9D9D9),
              fontSize: 12,
              height: null, //nag set na me ng flutter line height conversion sa figma bali yung sa figma, gamit nun default lineheight ni flutter
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 16), //gap between ng text sa end card and sa button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6AA0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  
                ),
              ),
              onPressed: () {
                //TODO: Navigate to announcements
                 Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 0),
                      pageBuilder: (_, __, ___) => AnnouncementsPage(userId: _userId),
                    ),
                  );
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
  } //idle election card end

  Widget _buildActiveItemsSliderCard(List<Map<String, dynamic>> items) { //
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 180,
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

  Widget _buildSliderItemCard(Map<String, dynamic> item) {
    final String type = item['type'] ?? '';
    final bool isOngoing = item['ongoing'] ?? false;
    final String title = (type == 'university' || type == 'proposal') ? 'UMak' : _userCollegeAbbreviation;
    final String subtitle = _formatType(type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 28, bottom: 21, right: 28),
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
          if (isOngoing) ...[
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
            const Text(
              "Election ended:",
              style: TextStyle(color: Color(0xFFD9D9D9), fontSize: 12),
            ),
            const SizedBox(height: 12),
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
                  final String id = item['id'];
                  final String itemType = item['type'];
                  // TODO: Navigate to Results Screen
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
    if (_sliderItems.isEmpty) {
      return _buildCurrentOfficialsSection(
        "$_userCollegeId Officials",
        _firebaseService.getCurrentOfficialsStream(_userCollegeId),
      );
    }
    final currentItem = _sliderItems[_currentActiveItemPage];
    final String type = currentItem['type'];
    final String id = currentItem['id'];
    final bool isOngoing = currentItem['ongoing'];

    if (isOngoing) {
      return _buildSlatesSection(id);
    }
    if (type == 'proposal') {
      return _buildCurrentOfficialsSection(
        "University Officials",
        _firebaseService.getUniversityOfficialsStream(),
      );
    } 
    else if (type == 'college') {
      return _buildCurrentOfficialsSection(
        "Newly Elected $_userCollegeId Officials",
        _firebaseService.getElectionResultsStream(id),
        isResults: true,
      );
    }
    return _buildCurrentOfficialsSection(
      "Newly Elected University Officials",
      _firebaseService.getElectionResultsStream(id),
      isResults: true,
    );
  }

  Widget _buildCurrentOfficialsSection(
    String title,
    Stream<QuerySnapshot> stream, {
    bool isResults = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.only(left: 4),

          child: Row(
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
              Padding(
                padding:EdgeInsets.only(right: 4),
                  child: GestureDetector( //see all na ok na, dalawa pala i2
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ElectedOfficialsPage(uid: _userId),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                      "See all",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF404040),
                          fontFamily: 'Geist',
                        ),
                      ),
                    )
                  ),
                )
            ],
          ),
        ),
        
        
        const SizedBox(height: 13), // gap between "CCIS Officials" and see all btn - ended election ng title see all btn and img placeholder
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print("Error loading officials: ${snapshot.error}");
              return Container(
                height: 180,
                alignment: Alignment.center,
                child: Text("Error: Could not load officials."),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return Container(
                height: 180,
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
        const SizedBox(height: 22), //hap between section 3 and section 2
      ],
    );
  }

  Widget _buildSlatesSection(String electionId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
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

              Padding(
                padding:EdgeInsets.only(right: 4),
                  child: GestureDetector( // see all na di okay per ok na, keyword purposes
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SlateListPage(electionId: electionId), 
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "See all",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF404040),
                          fontFamily: 'Geist',
                        ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        
        const SizedBox(height: 13), //ayon gap ne see all and slates title sa image placeholder
        StreamBuilder<QuerySnapshot>(
          stream: _firebaseService.getSlatesStream(electionId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print("Error loading slates: ${snapshot.error}");
              return Container(
                height: 180,
                alignment: Alignment.center,
                child: Text("Error: Could not load slates."),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final slates = snapshot.data!.docs;
            return Column(
              children: [
                SizedBox(
                  height: 180,
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
                          final slate = slates[index].data() as Map<String, dynamic>;
                          final String name = slate['name'] ?? 'Unnamed Slate';
                          final String description = slate['slogan'] ?? 'No description.';
                          final String? filePath = slate['img'] as String?;

                          String? publicUrl;
                          if (filePath != null && filePath.isNotEmpty) {
                            try {
                              publicUrl = Supabase.instance.client.storage
                                  .from('images')
                                  .getPublicUrl(filePath);
                            } catch (e) {
                              print('Error getting public URL: $e');
                              publicUrl = null;
                            }
                          }
                          
                          final String placeholderUrl = 'assets/account.svg';
                          final ImageProvider<Object> imageProvider =
                              (publicUrl != null)
                                  ? NetworkImage(publicUrl)
                                  : NetworkImage(placeholderUrl)
                                      as ImageProvider<Object>;

                          return Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  print('Error loading image: $exception');
                                },
                              ),
                            ),
                            child: Container(
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
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
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

  Widget _buildInfoCard(String title) {
    return Expanded(
      child: Container(
        height: 87,
        decoration: BoxDecoration(
          color: Color(0xFF5C6AA0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF354372),
            width: 0.5,
            ),
          /*boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: -2,
            ),
          ],*/
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
          height: 180,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.officials.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final officialDoc = widget.officials[index].data() as Map<String, dynamic>;
                  final String name = officialDoc['name'] ?? 'Unknown';
                  final String position = officialDoc['position'] ?? 'Unknown';
                  final String? filePath = officialDoc['img'] as String?;

                  String? publicUrl;
                  if (filePath != null && filePath.isNotEmpty) {
                    try {
                      publicUrl = Supabase.instance.client.storage
                          .from('images')
                          .getPublicUrl(filePath);
                    } catch (e) {
                      print('Error getting public URL: $e');
                      publicUrl = null;
                    }
                  }

                  return Container( // container nun elected and slates 
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isResults)
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
                          CircleAvatar( //keyword:electedlayout
                            radius: 35,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: (publicUrl != null)
                                ? NetworkImage(publicUrl)
                                : null,
                            child: (publicUrl == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),

                        const SizedBox(height: 16), // loob ng layout ng elected official image place holder
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
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.officials.length,
                    (index) => Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? const Color(0xFF354372)
                            : const Color(0xFFD9D9D9),
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