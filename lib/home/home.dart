import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'results.dart';
import 'profile.dart';
import 'election_gateway.dart';
import 'package:flutter/services.dart';

// Import your page "bodies"
import 'home_body.dart';
import 'candidates_view_body.dart';

// TODO: Import your Voting and Results pages
import 'voting_body.dart';
import 'elect_select.dart';

// Import pages for the action buttons
import 'announcement.dart';

// TODO: Import your Profile page

// Import your Firebase service
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // This will hold the currently selected tab index (0 = Home)
  int _selectedIndex = 0;
  DateTime? currentBackPressTime;

  // This is where we will put your 4 page widgets
  late final List<Widget> _pages;

  // This is the Firebase service to get user data
  final FirebaseService _firebaseService = FirebaseService();

  // home.dart

  @override
  void initState() {
    super.initState();
    _pages = [
      // 0. Home Tab
      HomeBody(uid: widget.uid, onTabChange: _onItemTapped),

      // 1. Candidates Tab
      CandidatesViewBody(uid: widget.uid),

      // 2. Voting Tab (Index 2)
      // In your home_screen.dart or where you define tabs
      ElectionGateway(
        uid: widget.uid,
        fetchElections:
            _firebaseService.getActiveElectionsForUser, // Fetches ONGOING only
        isResultMode: false, // Default (Voting logic applied)
        contentBuilder: (context, electionData, onBack) {
          return VotingHomePage(
            uid: widget.uid,
            electionData: electionData,
            onBack: onBack,
          );
        },
      ),

      // 3. Results Tab (Index 3)
      ElectionGateway(
        uid: widget.uid,
        emptyMessage: "No results available yet.",
        
        // CRITICAL CHANGE HERE:
        isResultMode: true, // <--- MUST BE TRUE to allow clicking even if voted

        // Fetch active AND ended elections here
        fetchElections: (uid) => _firebaseService.getRelevantElectionsForUser(uid),

        contentBuilder: (context, electionData, onBack) {
          return ElectionResultPage(
            uid: widget.uid,
            electionData: electionData,
            onBack: onBack,
          );
        },
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //nav area builder
  Widget _buildNavIcon(String iconName, int index) {
    final bool isActive = _selectedIndex == index;
    final String assetPath =
        'assets/bottom_nav/${iconName}_${isActive ? 'active' : 'inactive'}.svg';
    return SvgPicture.asset(assetPath, width: 21, height: 19);
  }

  // 2 backs swipe to exit app function - hindi to nagana ewan baket, kinuha koto sa luma eh pinaste kolang here
  void _handleBackPress() {
    DateTime now = DateTime.now();

    // A. If not on Home Tab, go back to Home Tab first
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    // B. Check if 2 seconds have passed since last press
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      
        // Update time
        currentBackPressTime = now;
        
        // Show SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Press back again to exit',
              style: TextStyle(fontFamily: 'Geist'),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF404040),
            behavior: SnackBarBehavior.floating, // Makes it float above bottom nav
            margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
          ),
        );
      } else {
        // C. If pressed within 2 seconds, Exit App
        SystemNavigator.pop();
      }
    }

  // --- START OF PERSISTENT DYNAMIC APP BAR LOGIC ---
  // This helper builds the correct title for the current tab
  Widget _buildAppBarTitle() {
    // This style is used for all titles
    const style = TextStyle(
      color: Color(0xFF414141),
      fontSize: 24,
      fontWeight: FontWeight.w600,
      fontFamily: 'Geist',
    );

    switch (_selectedIndex) {
      case 0:
        // For the Home tab, we fetch the user's name in real-time
        return _buildHomeTitle(style);
      case 1:
        return const Text("Candidates", style: style);
      case 2:
        return const Text("Voting", style: style);
      case 3:
        return const Text("Results", style: style);
      default:
        return const SizedBox.shrink();
    }
  }

  // A small, dedicated StreamBuilder just for the "Hello, [name]" title
  Widget _buildHomeTitle(TextStyle style) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firebaseService.getUserStream(widget.uid),
      builder: (context, snapshot) {
        String userName = "User";
        if (snapshot.hasData && snapshot.data!.data() != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String fullName = userData['name'] ?? 'User';
          if (fullName.trim().isNotEmpty) {
            userName = fullName.split(' ').first;
          }
        }
        return Text("Hello, $userName", style: style);
      },
    );
  }

  // These are the persistent action buttons for the AppBar - FIXED ripple effect
  List<Widget> _buildAppBarActions() {
    return [
      // First Button - Announcement
      Padding(
        padding: const EdgeInsets.only(right: 11),
        child: ClipOval(
          // This clips the ripple effect to a circle
          child: Material(
            color: const Color(0xFFEEEEEE),
            child: InkWell(
              onTap: () {
                // GOTO: ANNOUNCEMENT
                Navigator.push(
                  context,
                  /*PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 0),
                    pageBuilder: (_, __, ___) => AnnouncementsPage(userId: widget.uid),
                  ),*/
                  MaterialPageRoute(
                    builder: (context) => AnnouncementsPage(userId: widget.uid),
                  ),
                );
              },
              child: SizedBox(
                width: 45,
                height: 45,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 6, top: 12, bottom: 12),
                  child: SvgPicture.asset(
                    'assets/announcement.svg',
                    color: const Color(0xFF404040),
                    width: 21,
                    height: 23,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      //Second Button - Account
      Padding(
        padding: const EdgeInsets.only(right: 25),
        child: ClipOval(
          // Clips the ripple
          child: Material(
            color: const Color(0xFFEEEEEE),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(uid: widget.uid),
                  ),
                );
              },
              child: SizedBox(
                width: 45,
                height: 45,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/account.svg',
                    color: const Color(0xFF404040),
                    width: 21,
                    height: 23,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
  // --- END OF APP BAR LOGIC ---


  // popscope
  @override
  Widget build(BuildContext context) {
    // REPLACE WillPopScope WITH PopScope
    return PopScope(
      canPop: false, // 1. Prevent the system from closing the app automatically
      
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBackPress(); // 2. Call your custom logic
      },
      
      
        child: Scaffold(
        backgroundColor: Colors.white,

        // --- 1. THE APP BAR ---
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,

          //Flutter has built inn back btn sa app bar, this forces it to hide it
          automaticallyImplyLeading: false,

          // This controls the padding for the title
          titleSpacing: 25.0,

          // ripple feedback color
          iconTheme: IconThemeData(color: Colors.black),

          // This calls our helper to build the correct title
          //title: _buildAppBarTitle(),
          //with fade animation here:
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final fadeInAnimation = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
              );
              return FadeTransition(opacity: fadeInAnimation, child: child);
            },
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
            child: _buildAppBarTitle(),
          ),

          // This builds our action buttons
          actions: _buildAppBarActions(),

          // This sets the height of the AppBar
          toolbarHeight: 82, //72 from figma + 10 here
        ),

        // --- 2. THE BODY ---
        // This IndexedStack swaps the pages without losing their state
        body: AnimatedSwitcher(
          /* instant animation to
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          */

          // with fade animation, contemplating if maganda lagyan o mas maganda if instant
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final fadeInAnimation = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            );
            return FadeTransition(opacity: fadeInAnimation, child: child);
          },
          child: IndexedStack(
            key: ValueKey<int>(_selectedIndex),
            index: _selectedIndex,
            children: _pages,
          ),
        ),

        // --- 3. THE BOTTOM NAVIGATION BAR ---
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

            // This is the CORRECT onTap for the IndexedStack pattern
            onTap: _onItemTapped,

            currentIndex: _selectedIndex,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon('home', 0), // <-- This will now work
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon('slate', 1), // <-- This will now work
                label: "Candidate",
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon('voting', 2), // <-- This will now work
                label: "Vote",
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon('analytics', 3), // <-- This will now work
                label: "Analytics",
              ),
            ],
          ),
        ),    
      ),
    );
  } 
}
