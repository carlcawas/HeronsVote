import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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


  Future<DocumentSnapshot> _fetchUserData() async {
    return FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
       Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Error loading profile"));
            }

            // Extract data
            final data = snapshot.data!.data() as Map<String, dynamic>;
            
            final String name = data['fullName'] ?? data['name'] ?? 'Unknown';
            final String college = data['college_id'] ?? data['college'] ?? 'N/A';
            final String yearLevel = data['year_level'] ?? 'N/A';
            final String semester = data['semester'] ?? 'N/A';
            final String academicYear = data['academicYear'] ?? 'A.Y. 2025-2026';
            
            // CHECK VERIFICATION STATUS
            final bool isVerified = data['isVerified'] ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 1. HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                      ),
                      Text(
                        "Profile",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 24,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blueColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text(
                          "Log out",
                          style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Geist', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 2. CONDITIONAL WARNING CARD
                  if (!isVerified) ...[
                    _buildNotVerifiedWarning(),
                    const SizedBox(height: 20),
                  ],

                  // 3. STATUS & INFO SECTION
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Verification Status Card
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 190,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Verification status:",
                                style: TextStyle(color: _textColor, fontSize: 16, fontFamily: 'Geist', fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 15),
                              
                              // DYNAMIC ICON
                              isVerified 
                                ? SvgPicture.asset(
                                    'assets/check.svg',
                                    height: 60,
                                    width: 60,
                                  )
                                : SvgPicture.asset(
                                    'assets/UnverifiedIcon.svg', 
                                    height: 60,
                                    width: 60,
                                  ),
                                  
                              const SizedBox(height: 10),
                              
                              // DYNAMIC TEXT
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

                      // Right: Info
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

                  // Academic Year
                  _buildWideInfoCard(academicYear),
                  
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- NEW WIDGET: WARNING CARD ---
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to re-verification page
                print("Navigate to Verification");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _blueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Go to Profile settings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
      height: 56,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: _textColor, fontSize: 14, fontFamily: 'Geist', fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildWideInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: _textColor, fontSize: 14, fontFamily: 'Geist', fontWeight: FontWeight.w500),
      ),
    );
  }
}