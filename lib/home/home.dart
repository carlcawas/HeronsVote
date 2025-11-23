import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'results.dart';
import 'profile.dart';
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
  

  @override
  void initState() {
    super.initState();
    _pages = [

      // TODO: Replace with HomePage(uid: uid)
      HomeBody(uid: widget.uid, onTabChange: _onItemTapped),

      // TODO: Replace with CandidatePage(uid: uid)
      CandidatesViewBody(uid: widget.uid),

      // TODO: Replace with VotingPage(uid: uid)
      VotingGateway(uid: widget.uid),

      // TODO: Replace with ResultsPage(uid: uid)
      const ElectionResultPage(),
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
  Future<bool> _onWillPop() async { //saka ko nalang ayusin - rik
    DateTime now = DateTime.now();
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false; 
    }
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
        padding: const EdgeInsets.only(right: 8),
        child: ClipOval( // This clips the ripple effect to a circle
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
                  padding: const EdgeInsets.all(12),
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
        child: ClipOval( // Clips the ripple
          child: Material(
            color: const Color(0xFFEEEEEE),
            child: InkWell(
             onTap: () {
                 Navigator.push(
                   context, 
                   MaterialPageRoute(builder: (context) => ProfilePage(uid: widget.uid))
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


  @override
  Widget build(BuildContext context) {
    // WillPopScope handles the "press back again to exit" logic
    return WillPopScope(
      onWillPop: _onWillPop,
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
              return FadeTransition(
                opacity: fadeInAnimation,
                child: child,
              );
            },
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
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
            return FadeTransition(
              opacity: fadeInAnimation,
              child: child,
            );
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
                label: "Slates",
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

class VotingGateway extends StatefulWidget {
  final String uid;
  const VotingGateway({super.key, required this.uid});

  @override
  State<VotingGateway> createState() => _VotingGatewayState();
}

class _VotingGatewayState extends State<VotingGateway> {
  final FirebaseService _firebaseService = FirebaseService();
  Future<List<Map<String, dynamic>>>? _electionsFuture;
  Map<String, dynamic>? _selectedElection;
  
  @override
  void initState() {
    super.initState();
    _electionsFuture = _firebaseService.getActiveElectionsForUser(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _electionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF354372)));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text("Error loading elections: ${snapshot.error}"));
        }

        final elections = snapshot.data ?? [];

        if (elections.isEmpty) {
           return const Center(child: Text("No active elections at the moment."));
        }
        
        // User hasn't selected yet and there are multiple elections
        if (elections.length > 1 && _selectedElection == null) {
           return ElectionSelectionPage(
             uid: widget.uid, 
             activeElections: elections,
             onElectionSelected: (selected) {
               setState(() {
                 _selectedElection = selected;
               });
             },
           );
        } 
        
        // Single election or user has selected one
        else {
           final targetElection = _selectedElection ?? elections.first;
           
           return VotingHomePage(
             uid: widget.uid, 
             electionData: targetElection,
             // if there are multiple elections, allow going back
             onBack: elections.length > 1 
               ? () {
                   setState(() {
                     _selectedElection = null;
                   });
                 }
               : null,
           );
        }
      },
    );
  }
}