import 'package:flutter/material.dart';
import 'dart:async';
import 'announcement.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'slates_list.dart';
import 'elected_official_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile.dart';
import '../screens/Rules&Process/votingRules.dart'; 
import '../screens/Rules&Process/votingProcess.dart';


class HomeBody extends StatefulWidget {
  final String uid;
  final Function(int) onTabChange;
  
  const HomeBody({
    super.key, 
    required this.uid, 
    required this.onTabChange,
  });
  
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

  final PageController _candidatesPageController = PageController();
  int _currentCandidatesPage = 0;

  bool _isLoading = true; // Controls the main loading spinner
  
  Future<QuerySnapshot>? _cscOfficialsFuture;
  Future<QuerySnapshot>? _uscOfficialsFuture;
  StreamSubscription? _verifiedSub;
  
  // --- Snapshot data holders ---
  QuerySnapshot? _collegeElecSnap;
  QuerySnapshot? _uniElecSnap;
  QuerySnapshot? _proposalSnap;
  QuerySnapshot? _endedCollegeSnap;
  QuerySnapshot? _endedUniSnap;
  QuerySnapshot? _endedProposalSnap;
  QuerySnapshot? _latestCollegeElecSnap; 
  QuerySnapshot? _latestUniElecSnap; 

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
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.uid;
    _startDataListeners();
    _verifiedSub = _firebaseService.getUserStream(_userId).listen((userSnapshot) {
      if (!mounted) return;
      final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};
      setState(() {
        _isVerified = userData['isVerified'] ?? false;
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      _startDataListeners();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _verifiedSub?.cancel();
    _activeItemsPageController.dispose();
    _slatesPageController.dispose();
    _candidatesPageController.dispose();
    
    super.dispose();
  }

  // Initializes all data listeners
  Future<void> _startDataListeners() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
    final userSnapshot = await _firebaseService.getUserDoc(_userId);
    final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};
    _userCollegeAbbreviation = userData['college_id'] ?? '';
    _isVerified = userData['isVerified'] ?? false;
    _userCollegeId = userData['college_id'] ?? '';

    _cscOfficialsFuture = _firebaseService.getCurrentOfficials(_userCollegeId);
    _uscOfficialsFuture = _firebaseService.getUniversityOfficials();

    final results = await Future.wait([
      _firebaseService.getActiveUniversityElection(),
      _firebaseService.getActiveUniversityProposal(),
      _firebaseService.getRecentlyEndedUniversityElectionOnce(),
      _firebaseService.getRecentlyEndedUniversityProposalOnce(),
      _firebaseService.getActiveCollegeElection(_userCollegeId),
      _firebaseService.getRecentlyEndedCollegeElectionOnce(_userCollegeId),
      _firebaseService.getLatestUniversityElection().first,
      _firebaseService.getLatestCollegeElection(_userCollegeId).first,
    ]);

    if (!mounted) return;
    setState(() {
      _uniElecSnap = results[0];
      _proposalSnap = results[1];
      _endedUniSnap = results[2];
      _endedProposalSnap = results[3];
      _collegeElecSnap = results[4];
      _endedCollegeSnap = results[5];
      _latestUniElecSnap = results[6];
      _latestCollegeElecSnap = results[7];
      _isLoading = false;
    });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _collegeElecSnap = null;
        _uniElecSnap = null;
        _proposalSnap = null;
        _endedCollegeSnap = null;
        _endedUniSnap = null;
        _endedProposalSnap = null;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  void _processSliderItems() {
    // Ensure all data is available before processing
    if (_collegeElecSnap == null ||
        _uniElecSnap == null ||
        _proposalSnap == null ||
        _endedCollegeSnap == null ||
        _endedUniSnap == null ||
        _endedProposalSnap == null) {
      _sliderItems = [];
      return;
    }

    _activeItems = [];
    _recentlyEndedItems = [];

    // Check for active items
    if (_collegeElecSnap!.docs.isNotEmpty) {
      _activeItems.add({
        'type': 'college',
        'ongoing': true,
        ..._docToMap(_collegeElecSnap!.docs.first),
      });
    }
    if (_uniElecSnap!.docs.isNotEmpty) {
      _activeItems.add({
        'type': 'university',
        'ongoing': true,
        ..._docToMap(_uniElecSnap!.docs.first),
      });
    }
    if (_proposalSnap!.docs.isNotEmpty) {
      _activeItems.add({
        'type': 'proposal',
        'ongoing': true,
        ..._docToMap(_proposalSnap!.docs.first),
      });
    }

    // Always check for recently ended items
    if (_endedCollegeSnap!.docs.isNotEmpty) {
      final doc = _endedCollegeSnap!.docs.first;
      final end = doc['end'];
      if (end is Timestamp && _isRecentlyEnded(end)) {
        _recentlyEndedItems.add({
          'type': 'college',
          'ongoing': false,
          ..._docToMap(doc),
        });
      }
    }
    if (_endedUniSnap!.docs.isNotEmpty) {
      final doc = _endedUniSnap!.docs.first;
      final end = doc['end'];
      if (end is Timestamp && _isRecentlyEnded(end)) {
        _recentlyEndedItems.add({
          'type': 'university',
          'ongoing': false,
          ..._docToMap(doc),
        });
      }
    }
    if (_endedProposalSnap!.docs.isNotEmpty) {
      final doc = _endedProposalSnap!.docs.first;
      final end = doc['end'];
      if (end is Timestamp && _isRecentlyEnded(end)) {
        _recentlyEndedItems.add({
          'type': 'proposal',
          'ongoing': false,
          ..._docToMap(doc),
        });
      }
    }

    // Sort recently ended items
    _recentlyEndedItems.sort((a, b) {
      final aEnd = a['end'];
      final bEnd = b['end'];
      if (aEnd is! Timestamp && bEnd is! Timestamp) return 0;
      if (aEnd is! Timestamp) return 1;
      if (bEnd is! Timestamp) return -1;
      return bEnd.compareTo(aEnd);
    });

    // Create the combined list
    _sliderItems = [..._activeItems, ..._recentlyEndedItems];

    // Sort election cards based on priority
    _sliderItems.sort((a, b) {
      return _getPriority(b['type'], b['ongoing'])
          .compareTo(_getPriority(a['type'], a['ongoing']));
    });

    // Update bounds check for new list
    if (_currentActiveItemPage >= _sliderItems.length) {
      _currentActiveItemPage = 0;
      if (_activeItemsPageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_activeItemsPageController.hasClients) {
            _activeItemsPageController.jumpToPage(0);
          }
        });
      }
    }
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
  int _getPriority(String type, bool isOngoing) {
    int priority = 0;

    // Prioritize Ongoing status
    if (isOngoing) {
      priority += 100;
    }

    switch (type) {
      case 'university':
        priority += 3; // Highest type priority
        break;
      case 'college':
        priority += 2; // Medium type priority
        break;
      case 'proposal':
        priority += 1; // Lowest type priority
        break;
      default:
        break;
    }

    return priority;
  }

  @override
  Widget build(BuildContext context) {
    // Show main loading spinner until all data is loaded
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Data is loaded, process it
    _processSliderItems();

    // For UI update and building
    return RefreshIndicator(
      onRefresh: _startDataListeners,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 0, //di na need since individual widget is naka 24 na
        vertical: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 'Not Verified' message shows if user not verified
          if (!_isVerified) ...[
            _buildNotVerifiedWarningCard(),
            const SizedBox(height: 22), // gap ni not verified and ended or ongoing card
          ],

          // call election cards
          _buildSliderOrNoElectionCard(),
          const SizedBox(height: 12), // gap ni CCIS officials / SLATES sa idle card

          // Officials/Slates card
          _buildConditionalSecondSection(),

          // 'Before you vote' card
          Padding(
            padding: const EdgeInsets.only(left: 28), //seperate padding both part hence 24+4
            child: const Text("Before you vote",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF404040),
                )),
          ),
          const SizedBox(height: 16), //gap between before u vote title and respective btns
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: Row(
              children: [
                // TODO: ADD REDIRECT FUNCTIONS
                _buildInfoCard("Voting rules", const VotingRules()), 
                const SizedBox(width: 22),
                _buildInfoCard("Voting process", const VotingProcess()),
              ],
            ),
          ),
          const SizedBox(height: 12), //para san itech, ahh para sa extra space under before u vote section

        ],
      ),
      ),
    );
  }

  // not verified card
  Widget _buildNotVerifiedWarningCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.only(top: 20, left: 28, bottom: 21, right: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF7F7F7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account not Verified",
            style: TextStyle(
              color: Color(0xFF404040),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "It seems like your semester has ended,\nPlease re-verify your account",
            style: TextStyle(
              color: Color(0xFF747474),
              fontSize: 14,
              fontFamily: 'Geist',
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6AA0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
               Navigator.push(
                   context, 
                   MaterialPageRoute(builder: (context) => ProfilePage(uid: widget.uid))
                 );
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
  // not verified card end

  Widget _buildSliderOrNoElectionCard() {
    if (_sliderItems.isEmpty) {
      return _buildNoElectionCard();
    } else {
      return _buildActiveItemsSliderCard(_sliderItems);
    }
  }

  //idle election card
  Widget _buildNoElectionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
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
              height: null,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 16),
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
                    pageBuilder: (_, __, ___) =>
                        AnnouncementsPage(userId: _userId),
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
  }
  //idle election card end

  Widget _buildActiveItemsSliderCard(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    //para sa next prev btn
    final bool hasMultipleItems = items.length > 1;
    final bool showNextButton = hasMultipleItems && _currentActiveItemPage == 0;
    final bool showPreviousButton = _currentActiveItemPage > 0;

    return SizedBox(
      height: 204, //height prev 184 to account for the 3 dots lang to 184+16
      width: double.infinity,
      child: Stack(
        children: [ //ill add another card na 184

          SizedBox(
            height: 186, //actual card
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: _buildSliderItemCard(item),
                    );
                  },
                ),

                //"Previous" Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: showPreviousButton ? 1.0 : 0.0,
                    child: Transform.translate(
                      // An offset of (-10, 0) moves it 10 pixels to the LEFT
                      offset: const Offset(-12.0, 0.0), 
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),

                        icon: const Icon(Icons.arrow_back_ios_new, color:Color(0xFF747474)),
                        onPressed: !showPreviousButton
                            ? null
                            : () {
                                _activeItemsPageController.animateToPage(
                                  0, // Go to first card
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                      ),
                    ),
                  ),
                ),

                //"Next" Button
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: showNextButton ? 1.0 : 0.0,
                    child: Transform.translate(
                      // An offset of (10, 0) moves the widget 10 pixels to the RIGHT,
                      // achieving the "negative padding" effect you want.
                      offset: const Offset(12.0, 0.0), 
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        
                        icon: const Icon(Icons.arrow_forward_ios, color:Color(0xFF747474)),
                        onPressed: !showNextButton
                            ? null
                            : () {
                                _activeItemsPageController.animateToPage(
                                  1, // Go to second card
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                      ),
                    ),
                  ),
                ),

              ],
            )
          ),

          if (items.length > 1) //yung election dots
            Positioned(
              bottom: 0,
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
                          ? const Color(0xFF354372)
                          : const Color(0xFFD9D9D9)
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
    final String title = (type == 'university' || type == 'proposal')
        ? 'UMak'
        : _userCollegeAbbreviation;
    final String subtitle = _formatType(type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
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
                final endRaw = item['end'];
                if (endRaw is! Timestamp) {
                  return _buildTimerSection(Duration.zero);
                }
                final DateTime endTime = endRaw.toDate();
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
              height: 44,
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
                  widget.onTabChange(3);
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
    // Find the latest election IDs from pre-loaded data
    String? latestCollegeElectionId;
    if (_latestCollegeElecSnap?.docs.isNotEmpty ?? false) {
      latestCollegeElectionId = _latestCollegeElecSnap!.docs.first.id;
    }

    String? latestUniElectionId;
    if (_latestUniElecSnap?.docs.isNotEmpty ?? false) {
      latestUniElectionId = _latestUniElecSnap!.docs.first.id;
    }

    // Idle state
    if (_sliderItems.isEmpty) {
      // Try to show latest College officials as default
      if (latestCollegeElectionId != null) {
        return _buildCurrentOfficialsSection(
          "$_userCollegeAbbreviation Officials",
          _firebaseService.getElectionResultsStream(_userCollegeId).first,
        );
      } else {
        return _buildCurrentOfficialsSection(
          "University Officials",
          _firebaseService.getUniversityOfficials(),
        );
      }
    }

    // Active/Recent state
    if (_sliderItems.isEmpty) return const SizedBox.shrink();

    final safeIndex = _currentActiveItemPage
        .clamp(0, _sliderItems.length - 1)
        .toInt();
    final currentItem = _sliderItems[safeIndex];
    final String type = currentItem['type'];
    final String id = currentItem['id'];
    final bool isOngoing = currentItem['ongoing'];

    if (isOngoing) {
      // USC Election: Show Candidates
      if (type == 'university') {
        return _buildCandidatesSection(id);
      }

      // Proposal: Show USC Officials followed by CSC Officials
      if (type == 'proposal') {
        return _buildCombinedOfficialsSection(
          "Officials", // Label
          _cscOfficialsFuture ?? _firebaseService.getCurrentOfficials(_userCollegeId), 
          _uscOfficialsFuture ?? _firebaseService.getUniversityOfficials(),
        );
      }

      // College Election: Show Slates
      return _buildSlatesSection(id);
    }

    // Proposal State (Ongoing or Ended)
    if (type == 'proposal') {
      return _buildCurrentOfficialsSection(
        "University Officials",
        _firebaseService.getUniversityOfficials(),
      );
    }

    // Recently Ended College Election
    else if (type == 'college') {
      return _buildCurrentOfficialsSection(
        "Newly Elected $_userCollegeId Officials",
        _firebaseService.getElectionResultsStream(_userCollegeId).first, 
        isResults: true,
      );
    }

    // Recently Ended University Election
    return _buildCurrentOfficialsSection(
      "Newly Elected University Officials",
      _firebaseService.getUniversityOfficials(), 
      isResults: true,
    );
  }

  // combine two streams into one slider (CSC first, then USC)
  Widget _buildCombinedOfficialsSection(
    String title,
    Future<QuerySnapshot> cscFuture,
    Future<QuerySnapshot> uscFuture,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 28), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF404040),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: GestureDetector( // see all
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ElectedOfficialsPage(
                          uid: _userId,
                          defaultAffiliation: 'USC',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
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

        const SizedBox(height: 13),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24), //officials section margin
          child: FutureBuilder<QuerySnapshot>(
            future: cscFuture,
            builder: (context, cscSnapshot) {
              return FutureBuilder<QuerySnapshot>(
                future: uscFuture,
                builder: (context, uscSnapshot) {
                  if (cscSnapshot.connectionState == ConnectionState.waiting ||
                      uscSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 186,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final cscDocs = cscSnapshot.data?.docs ?? [];
                  final uscDocs = uscSnapshot.data?.docs ?? [];

                  // Combine lists: CSC first, then USC
                  final List<DocumentSnapshot> allOfficials = [...uscDocs, ...cscDocs];

                  if (allOfficials.isEmpty) {
                    return Container(
                      height: 186,
                      alignment: Alignment.center,
                      child: const Text("No officials found."),
                    );
                  }

                  return _OfficialsPageView(
                    officials: allOfficials,
                    isResults: false,
                    uscCount: uscDocs.length, // how many are CSC
                    collegeAbbreviation: _userCollegeAbbreviation, // Pass college abbreviation
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 22),
      ],
    );
  }

  Widget _buildCurrentOfficialsSection( //newly elected [college] official, [type] officials
    String title,
    Future<QuerySnapshot> future, {
    bool isResults = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 28), //itong padding ni elected officials and see all d2 banda 24+4
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
                padding: EdgeInsets.only(right: 28),
                child: GestureDetector( //see all
                  onTap: () {
                    String defaultAffiliation = 'USC'; // Default to USC
                    
                    // Check if the abbreviation is valid and the title contains it
                    if (_userCollegeAbbreviation.isNotEmpty &&
                        _userCollegeAbbreviation != '...' &&
                        title.contains(_userCollegeAbbreviation)) {
                      defaultAffiliation = _userCollegeAbbreviation;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ElectedOfficialsPage(
                          uid: _userId,
                          defaultAffiliation: defaultAffiliation, // Pass it here
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6), //see all button padding
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

        const SizedBox(height:13), // gap between "CCIS Officials" and see all btn - ended election ng title see all btn and img placeholder

        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 24), //padding ni newly elected

          child: FutureBuilder<QuerySnapshot>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Error loading officials: ${snapshot.error}");
                return Container(
                  height: 186,
                  alignment: Alignment.center,
                  child: Text("Error: Could not load officials."),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return Container(
                  height: 187,
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

        ),
        
        const SizedBox(height: 22), //gap between section 3 and section 2

      ],
    );
  }

  Widget _buildSlatesSection(String electionId) { //slates
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), //padding left right, may dineclare ako +12 sa baba para naka crop siya
      child: Column(
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
                  padding: EdgeInsets.only(right: 4),
                  child: GestureDetector( // see all
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SlateListPage(electionId: electionId),
                        ),
                      );
                    },
                    child: Container( // see all btn to
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const SizedBox(height: 13), //ayon gap ng see all and slates title sa image placeholder
          FutureBuilder<QuerySnapshot>(
            future: _firebaseService.getSlates(electionId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Error loading slates: ${snapshot.error}");
                return Container(
                  height: 186,
                  alignment: Alignment.center,
                  child: Text("Error: Could not load slates."),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return Container(
                  height: 186,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "No slates found.",
                    style: TextStyle(
                      color: Color(0xFF747474),
                      fontFamily: 'Geist',
                      fontSize: 14,
                    ),
                  ),
                );
              }

              final slates = snapshot.data!.docs;
              return Column(
                children: [
                  Container( 
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300, 
                      borderRadius: BorderRadius.circular(20),
                    ),
                    
                    height: 186,
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
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0), //ito pla yon dapat wla o huhu hirap hnapin, para may space yung items
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300, // Fallback color
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // IMAGE LAYER
                                  if (publicUrl != null)
                                    Image.network(
                                      publicUrl,
                                      fit: BoxFit.cover,
                                      // Shows a loading spinner while image loads
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      
                                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                        print('Error loading image: $exception');
                                        return Center(
                                          child: SvgPicture.asset(
                                            'assets/account.svg', // placeholder on error
                                            color: Colors.grey.shade600,
                                            width: 60,
                                            height: 60,
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    // Placeholder if no URL was provided
                                    Center(
                                      child: SvgPicture.asset(
                                        'assets/account.svg', // placeholder
                                        color: Colors.grey.shade600,
                                        width: 60,
                                        height: 60,
                                      ),
                                    ),
                                  
                                  // GRADIENT LAYER
                                  Container(
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
                                  ),

                                  // TEXT LAYER
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                              slates.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
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
          const SizedBox(height: 22), //space ni slates and beofre you vote section, ito need ma adjust
        ],
      ),
      
    );
    
  }

  // Section to display USC Candidates need to fix
  Widget _buildCandidatesSection(String electionId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), //margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Candidates",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF404040),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector( // see all
                    onTap: () {
                      // Switch to "Candidates" tab (Index 1)
                      widget.onTabChange(1); 
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
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
          const SizedBox(height: 13),
          
          FutureBuilder<QuerySnapshot>( //start2
            future: _firebaseService.getCandidatesByElectionId(electionId).first,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  height: 186,
                  alignment: Alignment.center,
                  child: const Text("Error: Could not load candidates."),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return Container(
                  height: 186,
                  alignment: Alignment.center,
                  child: const Text("No candidates found."),
                );
              }

              final candidates = snapshot.data!.docs;
              
              return Column(
                
                children: [
                  

                  Container(
                    height: 186,
                    margin: const EdgeInsets.symmetric(horizontal: 0.0), 
                    clipBehavior: Clip.antiAlias, 
                    decoration: BoxDecoration(
                      /*border: Border.all(
                                  color: Color(0xFF404040),
                                  width: 0.5,
                                ),*/
                      color: const Color(0xFF354372), 
                      borderRadius: BorderRadius.circular(20)
                    ),

                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _candidatesPageController,
                          itemCount: candidates.length,
                          onPageChanged: (int page) {
                            setState(() {
                              _currentCandidatesPage = page;
                            });
                          },
                          itemBuilder: (context, index) {
                            final candidate = candidates[index].data()
                                as Map<String, dynamic>;
                            final String name = candidate['name'] ?? 'Unknown';
                            final String position = candidate['position'] ?? 'Unknown';
                            final String? filePath = candidate['img'] as String?;

                            String? publicUrl;
                            if (filePath != null && filePath.isNotEmpty) {
                              try {
                                publicUrl = Supabase.instance.client.storage
                                    .from('images')
                                    .getPublicUrl(filePath);
                              } catch (e) {
                                publicUrl = null;
                              }
                            }

                            return Container(

                              margin: const EdgeInsets.symmetric(horizontal: 0.0),
                              padding: const EdgeInsets.symmetric(horizontal: 0.0),
                              clipBehavior: Clip.antiAlias,

                              decoration: BoxDecoration(
                                color: const Color(0xFF354372),
                                borderRadius: BorderRadius.circular(0), //radius ng inside container
                                //border: Border.all(color: Colors.grey.shade300),
                              ),

                              child: Row(//itonatalaga
                                children: [

                                  Expanded(
                                    flex: 7,
                                    child: SizedBox(
                                      height: double.infinity,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(        
                                              image: (publicUrl != null)
                                              ? DecorationImage(
                                                  image: NetworkImage(publicUrl),
                                                  fit: BoxFit.cover, 
                                                )
                                              : null,
                                            ),

                                            child: (publicUrl == null)
                                              ? const Icon(
                                                  Icons.person,
                                                  size: 35,
                                                  color: Colors.grey,
                                                )
                                              : null,
                                          ),

                                          if (publicUrl != null) // Gradient
                                          Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.transparent,// Left side
                                                  Color(0xFF354372),// Right side (Darker)
                                                ],
                                                stops: [0, 4.0], // Adjusts where the fading starts
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ),

                                  Expanded(
                                    flex: 7,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 6),

                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,

                                        children: [

                                          Text(
                                            position,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFF8F8F8),
                                            ),
                                          ),

                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFFD9D9D9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ),
                                  const SizedBox(height: 8),                              
                                ],
                              ),
                            );
                          },
                        ),
                        
                        // Dots indicator
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 6,
                                child: SizedBox(),
                              ),
                              Expanded(
                                flex: 7,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      candidates.length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: index == _currentCandidatesPage
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
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
        ],
      ),
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

  Widget _buildInfoCard(String title, Widget destination) {
    return Expanded(
      child: GestureDetector( 
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        
        child: Container(
          height: 84,        
          decoration: BoxDecoration(
            color: Color(0xFF5C6AA0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFF354372),
              width: 0.5,
            ),
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
      ),
    );
  }
}

// used for "Current Officials" and "Newly Elected"
class _OfficialsPageView extends StatefulWidget {
  final List<DocumentSnapshot> officials;
  final bool isResults;
  final int? uscCount; 
  final String? collegeAbbreviation;
  
  const _OfficialsPageView({
    required this.officials, 
    this.isResults = false,
    this.uscCount,
    this.collegeAbbreviation,
  });
  
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

  @override //my reference
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 186,
          margin: const EdgeInsets.symmetric(horizontal: 0.0), 
          clipBehavior: Clip.antiAlias, 
          decoration: BoxDecoration(
            /*border: Border.all(
                        color: Color(0xFF404040),
                        width: 0.5,
                      ),*/
            color: const Color(0xFF354372), 
            borderRadius: BorderRadius.circular(20)
          ),

          child: Stack(
            children: [
              PageView.builder(//pagebuilder
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
                  final String rawPosition = officialDoc['position'] ?? 'Unknown';
                  final String rawCollege = officialDoc['college_id'] ?? 'Unknown';
                  final String? filePath = officialDoc['img'] as String?;

                  String displayPosition = rawPosition;
                  String displayCollege = rawCollege;
                  
                  if (widget.uscCount != null && widget.collegeAbbreviation != null) {
                    if (index < widget.uscCount!) {
                      displayPosition = "USC - $rawPosition";
                    } else {
                      displayPosition = "${widget.collegeAbbreviation} - $rawPosition";
                    }
                  }

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

                  return Container( // container nun elected officials yun may trophy

                    margin: const EdgeInsets.symmetric(horizontal: 0.0),
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    clipBehavior: Clip.antiAlias,

                    decoration: BoxDecoration(
                      color: const Color(0xFF354372),
                      borderRadius: BorderRadius.circular(0), //radius ng inside container
                      //border: Border.all(color: Colors.grey.shade300),
                    ),

                    child: Row(
                      children: [

                        Expanded( //image part, trophy and  gradient--
                          flex: 7,
                          child: SizedBox(
                            height: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(        
                                    image: (publicUrl != null)
                                    ? DecorationImage(
                                        image: NetworkImage(publicUrl),
                                        fit: BoxFit.cover, 
                                      )
                                    : null,
                                  ),
                                  
                                  child: (publicUrl == null)
                                    ? const Icon(
                                        Icons.person,
                                        size: 35,
                                        color: Colors.grey,
                                      )
                                    : null,
                                ),

                                if (publicUrl != null) // Gradient
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,// Left side
                                          Color(0xFF354372),// Right side (Darker)
                                        ],
                                        stops: [0, 4.0], // Adjusts where the fading starts
                                      ),
                                    ),
                                  ),

                                if (widget.isResults)
                                Positioned( //trophy overlay
                                  top: 13,
                                  left: 13,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF5C6AA0),   
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3), // Shadow color (30% opacity)
                                          blurRadius: 6, // Softness of the shadow
                                          offset: const Offset(0, 3), // Horizontal and Vertical offset
                                        ),
                                      ],                                 
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ),
                        ),
                        
                        Expanded( //texts --
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              
                              children: [
                                Text(//position
                                  displayPosition,

                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF8F8F8),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(//name
                                  name,

                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFD9D9D9),
                                  ),
                                ),

                                const SizedBox(height: 0),

                                Text(//college
                                  displayCollege,

                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFD9D9D9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        ),

                      ],
                    ),
                  );
                },
              ),
              
              Positioned( //page dots
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    const Expanded(
                      flex: 6, //adjust if inadjust yun taas
                      child: SizedBox(),
                    ),
                    Expanded(
                      flex: 7, //adjust if inadjust yun taas
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
                                  ? const Color(0xFFF8F8F8)
                                  : const Color(0xFFD9D9D9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]
                  
                ),
              ),
            ],
          ),

        ),
      ],
    );
  }
}
