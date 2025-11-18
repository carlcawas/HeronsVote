import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Expandable Section Widget
class ExpandableSection extends StatefulWidget {
  final String title;
  final String content;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

//advocacy expanding place
class _ExpandableSectionState extends State<ExpandableSection> {
  bool _isExpanded = false;
  final int collapsedMaxLines = 3;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (25 * 2);

    return Container( //collapsible card i2
      width: availableWidth,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: const Color(0xFF404040),
              fontSize: 16,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.content,
            style: TextStyle(
              color: const Color(0xFF747474),
              fontSize: 14,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            maxLines: _isExpanded ? null : collapsedMaxLines,
            overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
          ),
          //see more if many text
          if (widget.content.length > 160) 
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _isExpanded ? 'See less' : 'See more',
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
    String truncatedName = widget.candidate.name.split(' ').take(2).join(' ') + '...';

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (25 * 2);

    final nameWidth = (availableWidth * 0.80) - 16;
    final ageWidth = (availableWidth * 0.20) + 4;
    final yearWidth = availableWidth * 0.25;
    final collegeWidth = (availableWidth * 0.75) - 12;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: topPadding + 102,
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
                    margin: const EdgeInsets.only(bottom: 22),
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
                      //name
                      Container(
                        width: nameWidth,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Name: ',
                              style: TextStyle(
                                color: const Color(0xFF747474),
                                fontSize: 12,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
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
                      const SizedBox(width: 12),
                      //age
                      Container(
                        width: ageWidth,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Age: ',
                              style: TextStyle(
                                color: const Color(0xFF747474),
                                fontSize: 12,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.candidate.age,
                                style: const TextStyle(
                                  color: Color(0xFF404040),
                                  fontSize: 14,
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  //year
                  Row(
                    children: [
                      Container(
                        width: yearWidth,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
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
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.candidate.year,
                                style: const TextStyle(
                                  color: Color(0xFF404040),
                                  fontSize: 14,
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      //college
                      Container(
                        width: collegeWidth,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
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
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.candidate.college,
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
                    ],
                  ),
                  //slate
                  Container(
                    width: availableWidth,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(16),
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
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.candidate.partylist,
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

                  // Advocacy Section
                  ExpandableSection(
                    title: 'Advocacy',
                    content: widget.candidate.advocacy,
                  ),

                  // Platform Section
                  ExpandableSection(
                    title: 'Platform',
                    content: widget.candidate.platform,
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
                  height: MediaQuery.of(context).padding.top,
                  color: Colors.white,
                ),

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