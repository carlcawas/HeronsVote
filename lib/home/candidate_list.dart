import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'list_format.dart';
import 'candidate_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CandidateListPage extends StatefulWidget {
  final String positionTitle;
  final String uid;

  const CandidateListPage({
    super.key,
    required this.positionTitle,
    required this.uid,
  });

  @override
  State<CandidateListPage> createState() => _CandidateListPageState();
}

class _CandidateListPageState extends State<CandidateListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  bool _skeletonVisible = true;

  late Future<String> _collegeIdFuture;

  @override
  void initState() {
    super.initState();
    _collegeIdFuture = _getUserId();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _skeletonVisible = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getUserId() async {
    String collegeId = "";
    final FirebaseService firebaseService = FirebaseService();
    final userData = await firebaseService.getDocument('users', widget.uid);
    if (userData != null) {
      collegeId = userData['college_id'];
    }
    return collegeId;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _collegeIdFuture, 
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userCollegeId = userSnapshot.data ?? "";
        return ReusableListPage(
          title: widget.positionTitle,
          onBack: () => Navigator.pop(context),
          items: [
            // Search bar (customize niyo nalang :DD)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: Color(0xFF404040),
                ),
                decoration: InputDecoration(
                  hintText: "Search name or slate...",
                  hintStyle: TextStyle(
                    fontFamily: 'Geist',
                    color: Colors.grey.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF747474)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(color: Color(0xFF5C6AA0), width: 1),
                  ),
                ),
              ),
            ),

            // Check if there is an ongoing USC Election
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseService().getActiveUniversityElectionStream(),
              builder: (context, uscSnapshot) {
                // Check if there is an ongoing CSC Election
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService().getActiveCollegeElectionStream(
                    userCollegeId,
                  ),
                  builder: (context, cscSnapshot) {
                    String targetCollegeId = "none";
                    bool isUscActive =
                        uscSnapshot.hasData && uscSnapshot.data!.docs.isNotEmpty;
                    bool isCscActive =
                        cscSnapshot.hasData && cscSnapshot.data!.docs.isNotEmpty;

                    if (isUscActive) {
                      targetCollegeId = "";
                    } else if (isCscActive) {
                      targetCollegeId = userCollegeId;
                    }

                    // If no election is active, show a message
                    if (!isUscActive && !isCscActive) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            "No active election found for this position.",
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseService().getCandidatesByPositionStream(
                        widget.positionTitle,
                        targetCollegeId,
                      ),

                      builder: (context, snapshot) {

                        //added for skeleton
                        //bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                        bool isLoading = snapshot.connectionState == ConnectionState.waiting || _skeletonVisible;
                        //

if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
  for (final doc in snapshot.data!.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final filePath = data['img'] as String?;
    if (filePath != null && filePath.isNotEmpty) {
      try {
        final url = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(filePath);
        precacheImage(NetworkImage(url), context);
      } catch (_) {}
    }
  }
}

                        //bool isLoading = true;

                        /*if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }*/

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        //final docs = snapshot.data?.docs ?? [];

                        //added fro skeleton
                        final List<QueryDocumentSnapshot?> docs = isLoading
                          ? List.generate(4, (index) => null)
                          : snapshot.data?.docs ?? [];
                        //

                        //added !isLoading && for skeleton
                        if (!isLoading && docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'No candidates found for ${widget.positionTitle}.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        List<Widget> candidateItems = [];
  
                        if (!isLoading) {
                          List<QueryDocumentSnapshot?> filteredDocs = docs.where((doc) {
                            final data = doc!.data() as Map<String, dynamic>;
                            final name = (data['name'] as String? ?? '').toLowerCase();
                            final slate = (data['slate'] as String? ?? '').toLowerCase();
                            return name.contains(_searchQuery) || slate.contains(_searchQuery);
                          }).toList();


                        /*List<QueryDocumentSnapshot> filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] as String? ?? '').toLowerCase();
                            final slate = (data['slate'] as String? ?? '').toLowerCase();

                            return name.contains(_searchQuery) || slate.contains(_searchQuery);
                          }).toList();
                          
                          if (filteredDocs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(30.0),
                              child: Center(
                                child: Text(
                                  "No candidates found matching your search.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }*/
                          
                          // Sorting
                          filteredDocs.sort((a, b) {

                            final dataA = a!.data() as Map<String, dynamic>;  // ✅ added !
                            final dataB = b!.data() as Map<String, dynamic>;  // ✅ added !

                            //final dataA = a.data() as Map<String, dynamic>;
                            //final dataB = b.data() as Map<String, dynamic>;

                            String slateA = dataA['slate'] ?? '';
                            if (slateA.trim().isEmpty) slateA = 'Independent';
                            
                            String slateB = dataB['slate'] ?? '';
                            if (slateB.trim().isEmpty) slateB = 'Independent';

                            bool isIndependentA = slateA == 'Independent';
                            bool isIndependentB = slateB == 'Independent';

                            // Sort by Slate
                            if (!isIndependentA && isIndependentB) return -1;
                            if (isIndependentA && !isIndependentB) return 1;

                            // Sort Alphabetically
                            String nameA = dataA['name'] ?? '';
                            String nameB = dataB['name'] ?? '';
                            return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                          });

                          // Map Firestore documents to CandidateListItem widgets

                          //final 
                          candidateItems = filteredDocs.map((doc) {

                            final data = doc!.data() as Map<String, dynamic>;  // ✅ added !

                            //final data = doc.data() as Map<String, dynamic>;

                            String? college = data['college_id'] as String?;
                            final year = data['year'];

                            if (college == null || college.isEmpty) {
                              college = 'USC';
                            }

                            String fullDetails;
                            if (college != null && year != null) {
                              fullDetails = '$college - $year Year';
                            } else if (college != null) {
                              fullDetails = college.toString();
                            } else {
                              fullDetails = "";
                            }

                            String slateVal = data['slate'] as String? ?? '';
                            if (slateVal.trim().isEmpty) {
                              slateVal = 'Independent';
                            }

                            final candidate = Candidate(
                              name: data['name'] ?? 'MissingNo?',
                              role: data['position'] ?? widget.positionTitle,
                              details: fullDetails,
                              age: data['age']?.toString() ?? 'N/A',
                              year: data['year'] ?? 'N/A',
                              college: data['college_id'] ?? 'N/A',
                              img: data['img'] as String?,
                              partylist: slateVal,
                              advocacy: data['advocacy'] ?? 'No advocacy provided.',
                              platform: data['platform'] ?? 'No platform provided.',
                            );

                            return CandidateListItem(
                              candidate: candidate,
                              partylistName: candidate.partylist,
                            );
                          }).toList();

                        } else {
                          candidateItems = List.generate(4, (index) {
                            return CandidateListItem(
                              candidate: Candidate(
                                name: "Loading Candidate Name",
                                role: widget.positionTitle,
                                details: "College - Year Level",
                                age: "N/A",
                                year: "N/A",
                                college: "N/A",
                                partylist: "Party List Name",
                                advocacy: "",
                                platform: "",
                              ),
                              partylistName: "Party List Name",
                            );
                          });
                        }

                        return Skeletonizer(
                          enabled: isLoading,
                          child: Column(children: candidateItems),
                        );

                      },
                    );
                  },
                );
              },
            ),
          ],
          emptyMessage: 'No candidates found', //
        );
      },
    );
  }
}

class CandidateListItem extends StatelessWidget {
  final Candidate candidate;
  final String partylistName;

  const CandidateListItem({
    super.key,
    required this.candidate,
    required this.partylistName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Future.delayed(const Duration(milliseconds: 100), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CandidateProfilePage(
                candidate: Candidate(
                  name: candidate.name,
                  age: candidate.age,
                  year: candidate.year,
                  college: candidate.college,
                  img: candidate.img,
                  partylist: partylistName,
                  advocacy: candidate.advocacy,
                  role: candidate.role,
                  details: candidate.details,
                  platform: candidate.platform,
                ),
              ),
            ),
          );
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 105,
          padding: const EdgeInsets.all(6), //ayusin ko sa figma
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              
            ],

            border: Border.all( //adjust kona rin sa figma
              color: const Color(0xFFEEEEEE),
              width: 0.5,
            ),

          ),
          child: Row(
            children: [
              // Candidate Image
              Container(
                width: 93,
                height: 93,
                margin: const EdgeInsets.only(right: 15),
                child: _buildSupabaseImageWidget(
                  filePath: candidate.img,
                  width: 93,
                  height: 93,
                  borderRadius: 16,
                  iconSize: 45,
                ),
              ),

              // Candidate Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        candidate.name,
                        style: const TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 16,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),

                      Text(
                        candidate.details,
                        style: TextStyle(
                          color: const Color(0xFF404040).withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        partylistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF404040).withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              ),

              // Right arrow button
              Skeleton.ignore( //hug lang ng skeleton ognore para di makita
                child: Container(
                  width: 40,
                  height: 93,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5C6AA0),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              )
   
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSupabaseImageWidget({
  required String? filePath,
  required double width,
  required double height,
  required double borderRadius,
  double iconSize = 50,
}) {
  String? publicUrl;
  if (filePath != null && filePath.isNotEmpty) {
    try {
      publicUrl = Supabase.instance.client.storage
          .from('images') // bucket name
          .getPublicUrl(filePath);
    } catch (e) {
      print('Supabase URL generation error: $e');
      publicUrl = null;
    }
  }

  Widget content = publicUrl != null
      ? Image.network(
          publicUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            //for smooth loading
            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
            //return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
          errorBuilder: (context, error, stackTrace) {
            return Skeleton.ignore(
              child: Center(
                child: Icon(
                  Icons.person,
                  size: iconSize,
                  color: Colors.grey,
                ),
              ),
            );
          
          },
        )
      : Skeleton.ignore(
        child: Center(
          child: Icon(
            Icons.person,
            size: iconSize,
            color: Colors.grey,
          ),
        ),
      );

  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFD9D9D9), // Placeholder background
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    ),
  );
}