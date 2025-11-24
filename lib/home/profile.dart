import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reverify/reverify_step1.dart';
import 'package:heronsvote/screens/splash_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:heronsvote/services/firebase_service.dart';

class ProfilePage extends StatefulWidget {
  final String uid;

  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color _textColor = const Color(0xFF404040);
  final Color _cardColor = const Color(0xFFF7F7F7);
  final Color _blueColor = const Color(0xFF5C6AA0);

  // check if offline
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) setState(() => _isOffline = true);
    } else {
      if (mounted) setState(() => _isOffline = false);
    }

    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (mounted) {
        setState(() {
          _isOffline = result.contains(ConnectivityResult.none);
        });
      }
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Log out",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF404040),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Are you sure you want to log out?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF747474),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF858FB8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Color(0xFF747474),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Yes Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const SplashScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6AA0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Yes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseService().getUserStream(widget.uid),
          builder: (context, snapshot) {
            String name = '...';
            String college = '...';
            String yearLevel = '...';
            String semester = '...';
            String section = '...';
            String studNum = '...';
            String academicYear = '...';
            bool isVerified = false;

            if (snapshot.hasData && snapshot.data!.exists && !_isOffline) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['fullName'] ?? data['name'] ?? 'Unknown';
              college = data['college_id'] ?? data['college'] ?? 'N/A';
              yearLevel = data['year_level'] ?? 'N/A';
              section = data['section'] ?? 'N/A';
              studNum = data['student_number'] ?? 'N/A';
              academicYear = data['academicYear'] ?? 'A.Y. 2025-2026';
              String rawSemester = data['semester'] ?? 'N/A';
              semester = rawSemester;
              
              if (rawSemester.toLowerCase().contains('first') ||
                  rawSemester.contains('1st')) {
                semester = "1st Semester";
              } else if (rawSemester.toLowerCase().contains('second') ||
                  rawSemester.contains('2nd')) {
                semester = "2nd Semester";
              } else if (rawSemester.toLowerCase().contains('summer')) {
                semester = "Summer Term";
              }
              
              isVerified = data['isVerified'] ?? false;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  //HEADER
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _blueColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "Profile",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 24,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blueColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Log out",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  if (_isOffline)
                    _buildOfflineWidget()
                  else if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.only(top: 100.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists)
                    const Padding(
                      padding: EdgeInsets.only(top: 100.0),
                      child: Center(child: Text("Error loading profile")),
                    )
                  else ...[
                    if (!isVerified) ...[
                      _buildNotVerifiedWarning(),
                      const SizedBox(height: 20),
                    ],

                    // STATUS & INFO SECTION
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verification Status Card
                        Expanded(
                          flex: 5,
                          child: Container(
                            height: 170,
                            padding: const EdgeInsets.only(
                              top: 19,
                              left: 20,
                              right: 20,
                              bottom: 19,
                            ),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Verification status:",
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 16,
                                    fontFamily: 'Geist',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 15),

                                isVerified
                                    ? SvgPicture.asset(
                                        'assets/check.svg',
                                        height: 60,
                                        width: 60,
                                      )
                                    : SvgPicture.asset(
                                        'assets/unverifiedIcon.svg',
                                        height: 60,
                                        width: 60,
                                      ),

                                const SizedBox(height: 10),
                                Text(
                                  isVerified ? "Verified" : "Not Verified",
                                  style: TextStyle(
                                    color: const Color(0xFF747474),
                                    fontSize: 14,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        //Info
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildSmallInfoCard(college),
                              const SizedBox(height: 10),
                              _buildSmallInfoCard(yearLevel),
                              const SizedBox(height: 10),
                              _buildSmallInfoCard(semester),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Name
                    _buildWideInfoCard(name),
                    const SizedBox(height: 12),
                    // section
                    _buildWideInfoCard(studNum),
                    const SizedBox(height: 12),
                    // studen num
                    _buildWideInfoCard(section),
                    const SizedBox(height: 12),

                    // Academic Year
                    _buildWideInfoCard(academicYear),

                    const SizedBox(height: 50),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  //unverified
  Widget _buildNotVerifiedWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account not Verified",
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "It seems like your semester has ended,\nPlease re-verify your account",
            style: TextStyle(
              color: Color(0xFF747474),
              fontSize: 14,
              fontFamily: 'Geist',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegistrationStep1(uid: widget.uid),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _blueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Re-verify now",
                style: TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfoCard(String text) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: _textColor,
          fontSize: 14,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWideInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _textColor,
          fontSize: 14,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOfflineWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 50,
                color: Color(0xFF747474),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "You're offline",
              style: TextStyle(
                color: Color(0xFF404040),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Please check your internet connection\nto view your profile.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF747474),
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _checkConnectivity,
              child: const Text(
                "Try Again",
                style: TextStyle(
                  color: Color(0xFF5C6AA0),
                  fontSize: 16,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
