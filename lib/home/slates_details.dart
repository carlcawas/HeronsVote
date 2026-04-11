import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'header.dart';
import 'slates_list.dart' show Slate, Candidate; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'slates_list.dart';
import 'candidate_profile.dart';
import 'sample_data.dart' as profile_data;
import 'package:skeletonizer/skeletonizer.dart';

class SlateDetailsPage extends StatefulWidget {
  final Slate slate;
  const SlateDetailsPage({super.key, required this.slate});

  @override
  State<SlateDetailsPage> createState() => _SlateDetailsPageState();
}

class _SlateDetailsPageState extends State<SlateDetailsPage> {
  double _scrollOffset = 0.0;
  final double scrollThreshold = 0.5;

  //addedSkeleton
  bool _skeletonVisible = true;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _skeletonVisible = false);
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final newOffset = notification.metrics.pixels.clamp(0.0, scrollThreshold);
      if (newOffset != _scrollOffset) {
        setState(() {
          _scrollOffset = newOffset;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    // Reference to the specific slate document
    final DocumentReference slateDocRef = FirebaseFirestore.instance
        .collection('slates')
        .doc(widget.slate.id);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: topPadding + 85,
                left: 25,
                right: 25,
                bottom: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  StreamBuilder<DocumentSnapshot>( 
                  stream: slateDocRef.snapshots(), 
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Text("Error loading info"); 
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    if (!snapshot.data!.exists) return const Text("Slate not found");

                    String advocacy = "No advocacy details provided.";
                    String platform = "No platform details provided.";

                    final data = snapshot.data!.data() as Map<String, dynamic>?;

                    if (data != null) {
                      advocacy = data['advocacy'] ?? advocacy;
                      platform = data['platform'] ?? platform;
                    }

                    return Column(
                      children: [
                        ExpandableSection(
                          title: 'Slate Advocacy',
                          description: advocacy,
                        ),
                        const SizedBox(height: 0),
                        ExpandableSection(
                          title: 'Slate Platform',
                          description: platform,
                        ),
                      ],
                    );
                  },
                ),

                  const SizedBox(height: 17),

                  StreamBuilder<QuerySnapshot>(
                    stream: slateDocRef.collection('candidates').orderBy('pos_rank').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Text("Error loading candidates");

                      //addedSkeleton + image preload step2
                      //bool isLoading = snapshot.connectionState == ConnectionState.waiting || _skeletonVisible;
                      bool isLoading = (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) || _skeletonVisible;
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        for (final doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final filePath = data['img_path'] as String?;
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
                      final List<Map<String, dynamic>?> items = isLoading
                      ? List.generate(4, (index) => null)
                      : snapshot.data!.docs
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .toList();
                      
                      /*if (!snapshot.hasData) { -> remove dis
                        return const Center(child: CircularProgressIndicator());
                      }*/

                      //end

                      //final docs = snapshot.data!.docs;  -> addSkeleton remove this
                      
                      // addSkeleton add (!isLoading && 
                      if (!isLoading && items.isEmpty) {
                        return const Text("No candidates found in this slate.");
                      }

                      //addedSkeleton enclose column
                      return Skeletonizer (
                        enabled: isLoading, 
                        child: Column(
                          children: items.map((docData) {

                          if (docData == null) {
                            return CandidateListItem(
                              candidate: Candidate(
                                name: "Loading Candidate Name",
                                role: "Position Title",
                                party: "Party Name",
                                details: "College - Year",
                                imgPath: null,
                              ),
                            );

                          }

                          final candidate = Candidate.fromMap(docData);
                          return CandidateListItem(candidate: candidate);
                          }).toList(),
                          
                        ),
                      );

                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          
          Positioned( //header with fade effect
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(1.0),
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: CustomHeader(
                    title: widget.slate.name.length > 15
                        ? '${widget.slate.name.substring(0, 15)}...'
                        : widget.slate.name,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}


// Expandable Section Widget
class ExpandableSection extends StatefulWidget {
  final String title;
  final String description; // Maps to 'description' in your snippet
  
  // New optional parameters based on your snippet
  final int hiddenCount;
  final bool isVisible;
  final bool isNew;
  final VoidCallback? onActionTap;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.description,
    // Default values ensure it works with your existing profile page
    this.hiddenCount = 0, 
    this.isVisible = true,
    this.isNew = false,
    this.onActionTap,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  bool _isContentExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Logic from your snippet
    final bool isStack = widget.hiddenCount > 0;
    
    // Safety check: If content is short, we can force expansion or hide the button
    // (Optional: You can remove this check if you ALWAYS want the button)
    final bool isTextShort = widget.description.length < 100;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: Container(
        // Added bottom margin so cards don't touch
        margin: const EdgeInsets.only(bottom: 22), 
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7E8E9)),
          boxShadow: [
            /*BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),*/
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8, left: 14, right: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Geist', // Added your font back
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Logic for the badge/icon on the right
                  if (isStack)
                    Container(
                      width: 46,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECECEC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("+${widget.hiddenCount}", style: const TextStyle(fontSize: 12, fontFamily: 'Geist')),
                          const SizedBox(width: 4),
                          const Icon(Icons.layers, size: 14, color: Color(0xFF2D2D2D)),
                        ],
                      ),
                    )
                  else if (widget.isNew) // Only show check if isNew is true
                    Opacity(
                      opacity: widget.isNew ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !widget.isNew,
                        child: GestureDetector(
                          onTap: widget.onActionTap,
                          child: Container(
                            width: 36,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECECEC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.check, size: 24, color: Color(0xFF404040)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // --- CONTENT (Description) ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    // Key forces rebuild on toggle
                    key: ValueKey("desc_${widget.title}_$_isContentExpanded"), 
                    widget.description, // Using 'content' from constructor
                    maxLines: _isContentExpanded ? null : 3,
                    overflow: _isContentExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14, 
                      fontFamily: 'Geist', // Added your font back
                      fontWeight: FontWeight.w500, // Matched your previous weight
                      color: const Color(0xFF747474), // Matched your previous color
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // --- TOGGLE BUTTON ---
              // Only show button if text is actually long enough to collapse
              if (!isTextShort) 
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isContentExpanded = !_isContentExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _isContentExpanded ? "See less" : "See more",
                        style: const TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 12,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CandidateListItem extends StatelessWidget {
  final Candidate candidate;

  const CandidateListItem({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // --- NEW INSTANT NAVIGATION ---
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CandidateProfilePage(
              candidate: profile_data.Candidate(
                name: candidate.name,
                role: candidate.role,
                partylist: candidate.party,
                img: candidate.imgPath,
                details: candidate.details,
                // Pass placeholders ("...") so the user sees it's loading
                // The Profile Page will replace these with real data in a split second
                age: '...', 
                year: '...',
                college: '...',
                advocacy: '', 
                platform: '',
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 114,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          ),
          child: Row(
            children: [
              // Image
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  image: candidate.imgPath != null && candidate.imgPath!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            Supabase.instance.client.storage
                                .from('images')
                                .getPublicUrl(candidate.imgPath!),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 15),
              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        candidate.role,
                        style: const TextStyle(
                          color: Color(0xFF404040),
                          fontSize: 18,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        candidate.name,
                        style: const TextStyle(
                          color: Color(0xFF747474),
                          fontSize: 12,
                          fontFamily: 'Geist',
                          height: 20 / 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${candidate.details}\n${candidate.party}',
                        style: const TextStyle(
                          color: Color(0xFF747474),
                          fontSize: 12,
                          fontFamily: 'Geist',
                          height: 20 / 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
              ),
              // Arrow
              Skeleton.ignore(
                child: Container(
                  width: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5C6AA0),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}