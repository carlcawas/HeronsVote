import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Expandable Section Widget
class ExpandableSection extends StatefulWidget {
  final String title;
  final String content; // Maps to 'description' in your snippet
  
  // New optional parameters based on your snippet
  final int hiddenCount;
  final bool isVisible;
  final bool isNew;
  final VoidCallback? onActionTap;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.content,
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
    final bool isTextShort = widget.content.length < 100;

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
                    widget.content, // Using 'content' from constructor
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

//Main page
class CandidateProfilePage extends StatefulWidget {
  final Candidate candidate;

  const CandidateProfilePage({super.key, required this.candidate});

  @override
  State<CandidateProfilePage> createState() => _CandidateProfilePageState();
}

class _CandidateProfilePageState extends State<CandidateProfilePage> {
  double _scrollOffset = 0.0;
  final double scrollThreshold = 0.5;

  //para sa pag pass ng value from slate
  late String displayAge;
  late String displayYear;
  late String displayCollege;
  late String displayAdvocacy;
  late String displayPlatform;
  
  @override
  void initState() {
    super.initState();
    // 1. Load initial data passed from previous screen
    displayAge = widget.candidate.age;
    displayYear = widget.candidate.year;
    displayCollege = widget.candidate.college;
    displayAdvocacy = widget.candidate.advocacy;
    displayPlatform = widget.candidate.platform;

    // 2. Fetch the rest of the data immediately
    _fetchRobustDetails();
  }
  Future<void> _fetchRobustDetails() async {
    try {
      Map<String, dynamic>? data;

      // PLAN A: Try fetching by ID (if available)
      if (widget.candidate.id != null && widget.candidate.id!.isNotEmpty) {
        final docSnap = await FirebaseFirestore.instance
            .collection('candidates')
            .doc(widget.candidate.id)
            .get();
        if (docSnap.exists) {
          data = docSnap.data();
        }
      }

      // PLAN B: If ID failed, search by Name and Position
      if (data == null) {
        final querySnap = await FirebaseFirestore.instance
            .collection('candidates')
            .where('name', isEqualTo: widget.candidate.name)
            .where('position', isEqualTo: widget.candidate.role)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          data = querySnap.docs.first.data();
        }
      }

      // 3. Update UI if data found
      if (data != null && mounted) {
        setState(() {
          displayAge = data!['age']?.toString() ?? 'N/A';
          displayYear = data!['year']?.toString() ?? 'N/A';
          displayCollege = data!['college_id'] ?? 'N/A';
          displayAdvocacy = data!['advocacy'] ?? 'No advocacy details provided.';
          displayPlatform = data!['platform'] ?? 'No platform details provided.';
        });
      }
    } catch (e) {
      print("Error fetching profile details: $e");
    }
  }
  //para sa pag pass ng value from slate --end

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
    String truncatedName = '${widget.candidate.name.split(' ').take(2).join(' ')}...';

    //final screenWidth = MediaQuery.of(context).size.width;
    //final availableWidth = screenWidth - (25 * 2);

    //final nameWidth = (availableWidth * 0.80) - 16;
    //final ageWidth = (availableWidth * 0.20) + 4;
    //final yearWidth = availableWidth * 0.25;
    //final collegeWidth = (availableWidth * 0.75) - 12;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: topPadding + 85,
                left: 24,
                right: 24,
                bottom: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 344,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 22), //gap between image and information
                    child: _buildSupabaseImageWidget(
                      filePath: widget.candidate.img,
                      width: double.infinity,
                      height: 344,
                      borderRadius: 20,
                      iconSize: 100,
                    ),
                  ),

                  Row(
                    children: [
                     
                      Expanded( //name
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE7E8E9)),
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Name: ',
                                style: TextStyle(
                                  color: const Color(0xFF747474),
                                  fontSize: 12,
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w500,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 4), //gap

                              Expanded( //text truncation
                                child: Text(
                                  widget.candidate.name,
                                  style: const TextStyle(
                                    color: Color(0xFF404040),
                                    fontSize: 14,
                                    fontFamily: 'Geist',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Container( //age
                        width: 80,//adjust lang to ito lang finix ko tsaka yung year
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        //margin: const EdgeInsets.only(bottom: 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE7E8E9)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Age: ',
                              style: TextStyle(
                                color: const Color(0xFF747474),
                                fontSize: 12,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(width: 4),

                            Text(
                              displayAge,
                              style: const TextStyle(
                                color: Color(0xFF404040),
                                fontSize: 14,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 12),
                  
                  Row(
                    children: [

                      Container( //year
                        width: 85,//adjust lang to ito lang finix ko tsaka yung age
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        //margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE7E8E9)),
                        ),
                        
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Year: ',
                              style: TextStyle(
                                color: const Color(0xFF747474),
                                fontSize: 12,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(width: 4),
                            
                            Text(
                                displayYear,
                                style: const TextStyle(
                                  color: Color(0xFF404040),
                                  fontSize: 14,
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Container( //college
                          //width: collegeWidth,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          //margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE7E8E9)),
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'College: ',
                                style: TextStyle(
                                  color: const Color(0xFF747474),
                                  fontSize: 12,
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w500,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 4),

                              Text(
                                  displayCollege,
                                  style: const TextStyle(
                                    color: Color(0xFF404040),
                                    fontSize: 14,
                                    fontFamily: 'Geist',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),     
                      )              
                    ],
                  ),

                  const SizedBox(height: 12),
                  
                  Container( //slate
                    //width: availableWidth,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7E8E9)),
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Slate affiliation: ',
                          style: TextStyle(
                            color: const Color(0xFF747474),
                            fontSize: 12,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 4),

                        Text(
                            widget.candidate.partylist,
                            style: const TextStyle(
                              color: Color(0xFF404040),
                              fontSize: 14,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Advocacy Section
                  ExpandableSection(
                    title: 'Advocacy',
                    content: displayAdvocacy,
                  ),

                  // Platform Section
                  ExpandableSection(
                    title: 'Platform',
                    content: displayPlatform,
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // Header 
          Positioned(
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
                        Colors.white.withOpacity(0.0,), 
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: CustomHeader(
                    title: truncatedName,
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
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.person,
                size: iconSize,
                color: Colors.grey,
              ),
            );
          },
        )
      : Center(
          child: Icon(
            Icons.person,
            size: iconSize,
            color: Colors.grey,
          ),
        );

  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFD9D9D9),
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    ),
  );
}