import 'package:flutter/material.dart';
import 'header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ElectedOfficialsPage extends StatefulWidget {
  final String uid;
  const ElectedOfficialsPage({super.key, required this.uid});

  @override
  State<ElectedOfficialsPage> createState() => _ElectedOfficialsPageState();
}

class _ElectedOfficialsPageState extends State<ElectedOfficialsPage> {
  String _selectedAffiliation = 'USC';

  late final FirebaseService _service = FirebaseService();
  late final Stream<QuerySnapshot> _uscStream;
  late final Stream<QuerySnapshot> _collegeStream;
  late String _collegeId;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.uid;
    FirebaseService().getUserStream(_userId).listen((userSnap) {
      final data = userSnap.data() as Map<String, dynamic>;
      setState(() {
        _collegeId = data['college_id'] ?? 'CCIS';
        _collegeStream = _service.getCurrentOfficialsStream(_collegeId);
      });
    });
    _uscStream = _service.getUniversityOfficialsStream();
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
            Expanded(child: _buildOfficialsList()),
          ],
        ),
      ),
    );
  }

  //filter ng usc or ccis
  Widget _buildAffiliationFilter() {
    const affiliations = ['USC', 'CCIS'];

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
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAffiliation = aff),
                    child: Container(
                      // Make the container transparent so the tap area
                      // is the full expanded width, but background is clear
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        aff,
                        style: isSelected ? selectedStyle : unselectedStyle,
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

  Widget _buildOfficialsList() {
    final stream = _selectedAffiliation == 'USC' ? _uscStream : _collegeStream;

    // Wrap the StreamBuilder in an AnimatedSwitcher
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      // Define the transition (fade)
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: StreamBuilder<QuerySnapshot>(
        // *** KEY CHANGE ***
        // Add a unique key based on the selection.
        // This tells the AnimatedSwitcher that the child has changed.
        key: ValueKey<String>(_selectedAffiliation),
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error loading officials'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final officials = snap.data!.docs
              .map((doc) =>
                  Official.fromFirestore(doc, _selectedAffiliation))
              .toList();

          if (officials.isEmpty) {
            return const Center(child: Text('No officials found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
            itemCount: officials.length,
            itemBuilder: (_, i) => OfficialListItem(official: officials[i]),
          );
        },
      ),
    );
  }
}

// OfficialListItem
class OfficialListItem extends StatelessWidget {
  final Official official;
  const OfficialListItem({Key? key, required this.official}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 114,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            const SizedBox(width: 14), //will adjust sa figma

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

class Official {
  final String id;
  final String name;
  final String position;
  final String party;
  final String details; // course + year
  final String? imgPath; // Supabase path
  final String affiliation; // 'USC' or college abbreviation

  Official({
    required this.id,
    required this.name,
    required this.position,
    required this.party,
    required this.details,
    this.imgPath,
    required this.affiliation,
  });

  factory Official.fromFirestore(
      DocumentSnapshot doc, String affiliation) {
    final data = doc.data() as Map<String, dynamic>;
    return Official(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      position: data['position'] ?? 'Unknown',
      party: data['party'] ?? 'No Party',
      details: data['details'] ?? 'No Details',
      imgPath: data['img'],
      affiliation: affiliation,
    );
  }
}