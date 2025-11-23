import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';

class ElectionSelectionPage extends StatefulWidget {
  final String uid;
  final List<Map<String, dynamic>> activeElections;
  final Function(Map<String, dynamic>) onElectionSelected;

  const ElectionSelectionPage({
    super.key,
    required this.uid,
    required this.activeElections,
    required this.onElectionSelected,
  });

  @override
  State<ElectionSelectionPage> createState() => _ElectionSelectionPageState();
}

class _ElectionSelectionPageState extends State<ElectionSelectionPage> {
  bool _isVerified = true; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _isVerified = userDoc.data()?['isVerified'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isVerified) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildNotVerifiedCard(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Election',
                      style: TextStyle(
                        color: Color(0xFF404040),
                        fontSize: 20,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${widget.activeElections.length} active elections.\nPlease select one to continue.',
                      style: const TextStyle(
                        color: Color(0xFF747474),
                        fontSize: 14,
                        fontFamily: 'Geist',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Active Election',
                style: TextStyle(
                  color: Color(0xFF404040),
                  fontSize: 14,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              //list election
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: widget.activeElections.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE5E5E5),
                      indent: 20,
                      endIndent: 20,
                    ),
                    itemBuilder: (context, index) {
                      final election = widget.activeElections[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            widget.onElectionSelected(election);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    election['title'] ?? 'Election',
                                    style: const TextStyle(
                                      color: Color(0xFF404040),
                                      fontSize: 16,
                                      fontFamily: 'Geist',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  //NOT VERIFIED 
  Widget _buildNotVerifiedCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF7F7F7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            padding: const EdgeInsets.all(25),
            // Using placeholder Icon - Replace with SvgPicture.asset('assets/not_verified.svg')
            child: const Icon(Icons.unpublished, size: 50, color: Color(0xFFED6C6A)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Account not Verified",
            style: TextStyle(
              color: Color(0xFF404040),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "It seems like your semester has ended,\nPlease re-verify your account",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF747474),
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                 Navigator.push(
                   context, 
                   MaterialPageRoute(builder: (context) => ProfilePage(uid: widget.uid))
                 );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6AA0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Go to Profile settings",
                style: TextStyle(
                  color: Colors.white,
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
}