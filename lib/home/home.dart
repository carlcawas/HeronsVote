import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

enum HomeState {
  noElection, // No ongoing election
  electionOngoing, // Election is active
  electionEnded, // Election has ended
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime electionEnd = DateTime.now().add(
    const Duration(minutes: 3, seconds: 50),
  );
  DateTime electionStart = DateTime.now().subtract(const Duration(days: 1));

  Timer? _timer;
  Duration timeLeft = Duration.zero;
  DateTime? currentBackPressTime;

  // State variables checker if verified voted or may election
  HomeState _currentHomeState = HomeState.electionOngoing;
  bool _isVerified = true;
  bool _electionExists = true;

  // For officials slider
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Variable to for changes in department and election type sa card (dito siguro save or use ung variable galing sa db )
  String _userDepartment = "CCIS";
  String _electionType = "CSC Election";

  // FOr slates slider
  final PageController _slatesPageController = PageController();
  int _currentSlatesPage = 0;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeLeft(),
    );
    _determineHomeState();
  }

  //to nagdedetermine ng state ng home
  void _determineHomeState() {
    if (!_electionExists) {
      _currentHomeState = HomeState.noElection;
    } else if (electionEnded) {
      _currentHomeState = HomeState.electionEnded;
    } else {
      _currentHomeState = HomeState.electionOngoing;
    }
  }

  //time for the timer sa elections
  void _updateTimeLeft() {
    final now = DateTime.now();
    setState(() {
      if (now.isBefore(electionStart)) {
        timeLeft = electionStart.difference(now);
      } else {
        timeLeft = electionEnd.difference(now);
      }

      if (timeLeft.isNegative) {
        timeLeft = Duration.zero;
        _timer?.cancel();
      }

      _determineHomeState();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool get electionEnded =>
      timeLeft.inSeconds ==
      0; //this will check if election ended not working yet

  //2 back swipe to exit app function
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

  // Method to simulate state changes for debug lng
  void _changeState(HomeState newState) {
    setState(() {
      _currentHomeState = newState;
      // Update variable based on state
      switch (newState) {
        case HomeState.noElection:
          _electionExists = false;
          _isVerified = true;
          _userDepartment = "CCIS";
          _electionType = "CSC Election";
          break;
        case HomeState.electionEnded:
          _electionExists = true;
          _isVerified = true;
          _userDepartment = "CCIS";
          _electionType = "CSC Election";
          electionEnd = DateTime.now().subtract(const Duration(hours: 1));
          break;
        case HomeState.electionOngoing:
          _electionExists = true;
          _isVerified = true;
          _userDepartment = "CCIS";
          _electionType = "CSC Election";
          electionEnd = DateTime.now().add(
            const Duration(minutes: 3, seconds: 50),
          );
          electionStart = DateTime.now().subtract(const Duration(days: 1));
          break;
      }
      _updateTimeLeft();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Hello, Name",
                      style: TextStyle(
                        color: Color(0xFF414141),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                    Row(
                      children: [
                        // State switcher dropdown for testing
                        DropdownButton<HomeState>(
                          value: _currentHomeState,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF414141),
                          ),
                          onChanged: (HomeState? newValue) {
                            if (newValue != null) {
                              _changeState(newValue);
                            }
                          },
                          items: HomeState.values.map((HomeState state) {
                            return DropdownMenuItem<HomeState>(
                              value: state,
                              child: Text(
                                state.toString().split('.').last,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ),
                        IconButton(
                          onPressed: () {
                            //TODO: NOTIF
                          },
                          icon: SvgPicture.asset(
                            'assets/announcement.svg',
                            color: Color(0xFF404040),
                            width: 20,
                            height: 25,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            //TODO : ACCOUNT
                          },
                          icon: SvgPicture.asset(
                            'assets/account.svg',
                            color: const Color(0xFF404040),
                            width: 21,
                            height: 23,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // NOT VERIFIED WARNING
                if (!_isVerified) ...[
                  _buildNotVerifiedWarningCard(),
                  const SizedBox(height: 30),
                ],

                // Reg election shows for all election state)
                _buildElectionCardByState(),
                const SizedBox(height: 30),

                // Conditional Officials/Slates area based on election
                if (_currentHomeState != HomeState.noElection &&
                    _currentHomeState != HomeState.electionEnded) ...[
                  _buildSlatesSection(), // Show slates for ongoing
                ] else ...[
                  _buildCurrentOfficialsSection(), // Show officials (current or newly elected)
                ],
                // Before vote area
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
                    _buildInfoCard("Voting rules"),
                    const SizedBox(width: 22.7),
                    _buildInfoCard("Voting process"),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Bottom nav
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
                //TODO: index checker para sa nav to lipat lipat
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
      ),
    );
  }

  //nav area builder
  Widget _buildNavIcon(String iconName, int index) {
    final bool isActive = _selectedIndex == index;
    final String assetPath =
        'assets/bottom_nav/${iconName}_${isActive ? 'active' : 'inactive'}.svg';

    return SvgPicture.asset(
      assetPath,
      width: 21,
      height: 19,
    );
  }

  Widget _buildElectionCardByState() {
    switch (_currentHomeState) {
      case HomeState.noElection:
        return _buildNoElectionCard();
      case HomeState.electionEnded:
        return _buildElectionEndedCard();
      case HomeState.electionOngoing:
      default:
        return _buildElectionOngoingCard();
    }
  }

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
                _userDepartment,
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
            "No active election. Check Announcements \nfor updates.",
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
                // TODO: Navigate to election info or announcements
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

  Widget _buildCurrentOfficialsSection() {
    final String sectionTitle = _currentHomeState == HomeState.electionEnded
        ? "Newly Elected Officials"
        : "Current Officials";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle, // title
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF404040),
              ),
            ),
            GestureDetector(
              onTap: () {
                //TODO: Navigate to officials
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
        _currentHomeState == HomeState.electionEnded
            ? _buildNewlyElectedOfficialsSlider()
            : _buildOfficialsSlider(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildNewlyElectedOfficialsSlider() {
    // sample data change based on db itech
    final List<Map<String, String>> electedOfficials = [
      {'name': 'Tokyo Athena', 'position': 'President'},
      {'name': 'Vonh Earl', 'position': 'Vice President'},
      {'name': 'Alice Gou', 'position': 'Secretary'},
      {'name': 'Princess Sarah', 'position': 'Treasurer'},
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: electedOfficials.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final official = electedOfficials[index];
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
                        // Winner pede tanggalin if panget napagtripan lng
                        Stack(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF5C6AA0).withOpacity(0.1),
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
                              top: -2,
                              right: -2,
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
                        ),
                        const SizedBox(height: 16),
                        Text(
                          official['name']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414141),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          official['position']!,
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
                    electedOfficials.length,
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

  //Officials widget
  Widget _buildOfficialsSlider() {
    // Example officials data
    final List<Map<String, String>> officials = [
      {'name': 'Tokyo Athena', 'position': 'President'},
      {'name': 'Vonh Earl', 'position': 'Vice President'},
      {'name': 'Alice Gou', 'position': 'Secretary'},
      {'name': 'Princess Sarah', 'position': 'Treasurer'},
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: officials.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final official = officials[index];
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
                          official['name']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414141),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          official['position']!,
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
              // Dots overlay on top of PageView
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    officials.length,
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

  Widget _buildSlatesSection() {
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
        _buildSlatesSlider(),
        const SizedBox(height: 30),
      ],
    );
  }

  // Slates Area
  Widget _buildSlatesSlider() {
    //Sample slates data change based on db
    final List<Map<String, String>> slates = [
      {
        'name': 'Unity Party',
        'description': 'Leading with innovation and unity',
      },
      {'name': 'Progress', 'description': 'Moving forward together'},
      {'name': 'Vision', 'description': 'Building a better future'},
      {'name': 'Student First', 'description': 'Putting students first'},
    ];

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
                  final slate = slates[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(0xFFD9D9D9)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Slate or picture
                        Container(
                          width: 70,
                          height: 70,
                          child: const Icon(
                            Icons.people,
                            size: 35,
                            color: Color(0xFF5C6AA0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slate['name']!, //change name
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414141),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slate['description']!, //desc or pede kahit ano
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
              //Dots for sliders
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

  //Ongoing election
  Widget _buildElectionOngoingCard() {
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
                _userDepartment,
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _electionType,
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 41),
          _buildTimerSection(timeLeft), //timer build
        ],
      ),
    );
  }

  //Ended election area
  Widget _buildElectionEndedCard() {
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
          // Department and Election Type next to each other
          Row(
            children: [
              Text(
                _userDepartment, // Dynamic department based on user to
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(width: 14),
              Text(
                _electionType, //election type
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
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
              onPressed: () {
                //TODO: VIEW Result
              },
              child: const Text(
                "View result",
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

  //to ung timer build lng tho or UI lng
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

  //same here build ng time box dito naman ung text sa inner like 05 then days
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

  //Info card Before you vate box are voting rules and stuff
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

  //not working not sure if working  not verified area
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
                // TODO: Navigate to profile settings
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
