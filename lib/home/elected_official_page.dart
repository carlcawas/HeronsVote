import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'header.dart';
import '../services/firebase_service.dart';

class ElectedOfficialsPage extends StatefulWidget {
  final String uid;
  final String? defaultAffiliation; // Accepts the default tab to show

  const ElectedOfficialsPage({
    super.key,
    required this.uid,
    this.defaultAffiliation,
  });

  @override
  State<ElectedOfficialsPage> createState() => _ElectedOfficialsPageState();
}

class _ElectedOfficialsPageState extends State<ElectedOfficialsPage> {
  late String _selectedAffiliation;
  late final FirebaseService _service = FirebaseService();
  String? _collegeId;
  String _collegeAbbreviation = '...';
  late final String _userId;

  // State variables for pre-loading data
  Stream<QuerySnapshot>? _uscDisplayStream;
  Stream<QuerySnapshot>? _cscDisplayStream;

  bool _isUscLoading = true;
  bool _isCscLoading = true;
  bool _uscHasNoResults = false;
  bool _cscHasNoResults = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.uid;

    // Set the initial tab based on the navigation parameter
    _selectedAffiliation = widget.defaultAffiliation ?? 'USC';
    
    // Pre-fill button text if coming from home page
    if (_selectedAffiliation != 'USC') {
      _collegeAbbreviation = _selectedAffiliation;
    }

    // 1. Kick off the USC stream logic immediately
    _determineUscStream();

    // 2. Listen for the user's college_id to load
    FirebaseService().getUserStream(_userId).listen((userSnap) {
      final data = userSnap.data() as Map<String, dynamic>;
      final newCollegeId = data['college_id'];

      if (mounted) {
        // Update the button label
        setState(() {
          _collegeAbbreviation = newCollegeId ?? 'CSC';
        });

        // Check if the college_id is new
        if (newCollegeId != _collegeId) {
          _collegeId = newCollegeId;

          if (_collegeId != null) {
            // 3. Kick off the CSC stream logic now
            _determineCscStream(_collegeId!);
          } else {
            // Handle case where user has no college_id
            setState(() {
              _isCscLoading = false;
              _cscHasNoResults = true;
            });
          }
        }
        
        // Sync selection in case the abbreviation loaded
        if (_selectedAffiliation != 'USC') {
          setState(() {
            _selectedAffiliation = _collegeAbbreviation;
          });
        }
      }
    });
  }

  /// Finds the latest USC election and sets the stream or no-results flag.
  void _determineUscStream() async {
    final electionQuery = await _service.getLatestUniversityElection().first;
    if (!mounted) return;

    if (electionQuery.docs.isNotEmpty) {
      final String electionId = electionQuery.docs.first.id;
      setState(() {
        _uscDisplayStream = _service.getElectionResultsStream(electionId);
        _isUscLoading = false;
        _uscHasNoResults = false;
      });
    } else {
      // No USC election found
      setState(() {
        _isUscLoading = false;
        _uscHasNoResults = true;
      });
    }
  }

  /// Finds the latest CSC election OR its fallback, then sets the stream.
  void _determineCscStream(String collegeId) async {
    setState(() {
      _isCscLoading = true;
      _cscHasNoResults = false;
    });

    final electionQuery =
        await _service.getRecentlyEndedCollegeElection(collegeId).first;
    if (!mounted) return;

    if (electionQuery.docs.isNotEmpty) {
      final String electionId = electionQuery.docs.first.id;
      setState(() {
        _cscDisplayStream = _service.getElectionResultsStream(electionId);
        _isCscLoading = false;
      });
    } else {
      // Fallback to current officials
      setState(() {
        _cscDisplayStream = _service.getCurrentOfficialsStream(collegeId);
        _isCscLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(
              title: 'Elected Officials',
              onBack: () => Navigator.pop(context),
            ),
            _buildAffiliationFilter(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300), // Fade duration
                // Add the fade transition
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildOfficialsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// This is the filter from Version 1, but updated with
  /// the dynamic affiliation logic from Version 2.
  Widget _buildAffiliationFilter() {
    final affiliations = ['USC', _collegeAbbreviation];

    // Define text styles for clarity
    const selectedStyle = TextStyle(
      color: Color(0xFFECECEC),
      fontWeight: FontWeight.w700,
      fontFamily: 'Geist',
      fontSize: 14,
    );
    const unselectedStyle = TextStyle(
      color: Color(0xFF404040),
      fontWeight: FontWeight.w500,
      fontFamily: 'Geist',
      fontSize: 14,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Layer 1: The sliding background
            AnimatedAlign(
              alignment: _selectedAffiliation == 'USC'
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: FractionallySizedBox(
                widthFactor: 0.5, // 2 items, so 50% width
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6AA0),
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),

            // Layer 2: The text and tap handlers
            Row(
              children: affiliations.map((aff) {
                final isSelected = aff == _selectedAffiliation;
                final bool isDisabled = aff == '...';

                return Expanded(
                  child: GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () => setState(() => _selectedAffiliation = aff),
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        aff,
                        style: isSelected
                            ? selectedStyle
                            : (isDisabled
                                ? unselectedStyle.copyWith(
                                    color: Colors.grey[400])
                                : unselectedStyle),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// This is the list-switching logic from Version 2.
  /// It selects the pre-loaded stream to display.
  Widget _buildOfficialsList() {
    // Use a key to help the AnimatedSwitcher differentiate the two lists
    if (_selectedAffiliation == 'USC') {
      // --- Show USC List ---
      if (_isUscLoading) {
        return const Center(
            key: ValueKey('usc_loading'), child: CircularProgressIndicator());
      }
      if (_uscHasNoResults) {
        return const Center(
            key: ValueKey('usc_no_results'),
            child: Text('No election results found.'));
      }
      return _OfficialsListBuilder(
        key: const ValueKey('usc_list'),
        stream: _uscDisplayStream!,
        affiliation: 'USC',
      );
    } else {
      // --- Show CSC List ---
      if (_isCscLoading) {
        return const Center(
            key: ValueKey('csc_loading'), child: CircularProgressIndicator());
      }
      if (_cscHasNoResults) {
        return const Center(
            key: ValueKey('csc_no_results'),
            child: Text('No officials found for your college.'));
      }
      return _OfficialsListBuilder(
        key: const ValueKey('csc_list'),
        stream: _cscDisplayStream!,
        affiliation: _collegeAbbreviation,
      );
    }
  }
}

/// This widget just builds the ListView from a given stream.
class _OfficialsListBuilder extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String affiliation;

  const _OfficialsListBuilder({
    super.key,
    required this.stream,
    required this.affiliation,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error loading officials'));
        }
        if (!snap.hasData) {
          // This shows a brief spinner as the pre-loaded stream
          // gets its first batch of data.
          return const Center(child: CircularProgressIndicator());
        }

        final officials = snap.data!.docs
            .map((doc) => Official.fromFirestore(doc, affiliation))
            .toList();

        if (officials.isEmpty) {
          return const Center(child: Text('No officials found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
          itemCount: officials.length,
          itemBuilder: (_, i) => OfficialListItem(official: officials[i]),
        );
      },
    );
  }
}

// OfficialListItem
class OfficialListItem extends StatelessWidget {
  final Official official;
  const OfficialListItem({Key? key, required this.official}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 114,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Official's image
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                image: official.imgPath != null
                    ? DecorationImage(
                        image: NetworkImage(
                          Supabase.instance.client.storage
                              .from('images')
                              .getPublicUrl(official.imgPath!),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 15),

            // Official's details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    official.position,
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 20,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    official.name,
                    style: const TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                      height: 20 / 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${official.details}\n${official.party}',
                    style: const TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                      height: 20 / 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Right Arrow
            Container(
              width: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF5C6AA0),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Official class (using the V2 factory)
class Official {
  final String id;
  final String name;
  final String position;
  final String party;
  final String details;
  final String? imgPath;
  final String affiliation;

  Official({
    required this.id,
    required this.name,
    required this.position,
    required this.party,
    required this.details,
    this.imgPath,
    required this.affiliation,
  });

  factory Official.fromFirestore(DocumentSnapshot doc, String affiliation) {
    final data = doc.data() as Map<String, dynamic>;

    final college = data['college'];
    final year = data['year'];

    String fullDetails;

    // This is the improved factory logic from V2
    if (college != null && year != null) {
      fullDetails = '$college - $year Year';
    } else if (college != null) {
      fullDetails = college.toString();
    } else if (year != null) {
      fullDetails = '$year Year';
    } else {
      fullDetails = data['details'] ?? 'No Details';
    }

    return Official(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      position: data['position'] ?? 'Unknown',
      party: data['party'] ?? 'No Party',
      details: fullDetails,
      imgPath: data['img'],
      affiliation: affiliation,
    );
  }
}