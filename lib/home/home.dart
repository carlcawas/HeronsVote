import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime electionEnd = DateTime.now().add(
    const Duration(minutes: 3, seconds: 50), //test if change ung election ended
  );
  Timer? _timer;
  Duration timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeLeft(),
    );
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    setState(() {
      timeLeft = electionEnd.difference(now);
      if (timeLeft.isNegative) {
        timeLeft = Duration.zero;
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get electionEnded => timeLeft.inSeconds == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      IconButton(
                        onPressed: () {
                          //TODO: NOTIF
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF414141),
                          size: 30,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          //TODO : ACCOUNT
                        },
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          color: Color(0xFF414141),
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Card election
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 15,
                  left: 25,
                  bottom: 35,
                  right: 25,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF858FB8), Color(0xFF3B4052)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CCIS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 50),
                    if (!electionEnded) ...[
                      const SizedBox(height: 8),
                      _buildTimerSection(timeLeft),
                    ] else ...[
                      const Text(
                        "Election ended:",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
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
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Slates area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Slates",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF414141),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      //TODO: Slates 
                    },
                    child: const Text(
                      "See all",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5C6AA0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(child: Text("Slates placeholder")),
              ),

              const SizedBox(height: 30),

              // Before vote area
              const Text(
                "Before you vote",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF414141),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoCard("Voting rules"),
                  _buildInfoCard("Voting process"),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // Bottom nav
      bottomNavigationBar: BottomNavigationBar(
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: "Slates",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote_outlined),
            label: "Vote",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: "Analytics",
          ),
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
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildTimeBox(
                "${timeLeft.inDays.toString().padLeft(2, '0')}",
                "Days",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeBox(
                "${(timeLeft.inHours % 24).toString().padLeft(2, '0')}",
                "Hours",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeBox(
                "${(timeLeft.inMinutes % 60).toString().padLeft(2, '0')}",
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontFamily: 'Geist',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
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
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF414141),
            ),
          ),
        ),
      ),
    );
  }
}
