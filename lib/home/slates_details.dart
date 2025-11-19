import 'package:flutter/material.dart';
import 'header.dart';
import 'slates_list.dart' show Slate, Candidate;

class SlateDetailsPage extends StatefulWidget {
  final Slate slate;
  const SlateDetailsPage({super.key, required this.slate});
  @override
  State<SlateDetailsPage> createState() => _SlateDetailsPageState();
}

class _SlateDetailsPageState extends State<SlateDetailsPage> {
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
    String truncatedTitle = widget.slate.name.length > 15
        ? '${widget.slate.name.substring(0, 15)}...'
        : widget.slate.name;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: topPadding + 102,
                left: 25,
                right: 25,
                bottom: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slate Advocacy Section
                  DetailsCard(
                    title: 'Slate Advocacy',
                    content: widget.slate.advocacy,
                  ),
                  const SizedBox(height: 17),
                  // Platform
                  DetailsCard(
                    title: 'Slate Platform',
                    content: widget.slate.platform,
                  ),
                  const SizedBox(height: 17),
                  // Candidates
                  ...widget.slate.candidates.map(
                    (candidate) => CandidateListItem(candidate: candidate),
                  ),

                  const SizedBox(height: 30),
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
                    title: truncatedTitle,
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

// Widget for Advocacy and Platform sections
class DetailsCard extends StatefulWidget {
  final String title;
  final String content;

  const DetailsCard({super.key, required this.title, required this.content});
  @override
  State<DetailsCard> createState() => _DetailsCardState();
}

class _DetailsCardState extends State<DetailsCard> {
  bool _isExpanded = false;
  final int collapsedMaxLines = 5;

  @override
  Widget build(BuildContext context) {
    final int? currentMaxLines = _isExpanded ? null : collapsedMaxLines;
    final TextOverflow currentOverflow = _isExpanded
        ? TextOverflow.clip
        : TextOverflow.ellipsis;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 13, left: 20, right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF404040),
              height: 20 / 16,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            widget.content,
            style: const TextStyle(
              fontSize: 14,
              height: 19 / 14,
              fontFamily: 'Geist',
              color: Color(0xFF747474),
            ),
            maxLines: currentMaxLines,
            overflow: currentOverflow,
          ),
          const SizedBox(height: 11),

          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _isExpanded ? 'See less' : 'See more',
                  style: const TextStyle(
                    color: Color(0xFF404040),
                    fontSize: 12,
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

// Widget for Candidate List Items
class CandidateListItem extends StatelessWidget {
  final Candidate candidate;

  const CandidateListItem({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: EdgeInsets.all(7),
        height: 114,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            //image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFFD9D9D9), //imahe
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
            ),
            const SizedBox(width: 15),
            // Candidate Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    candidate.role,
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 20,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    candidate.name,
                    style: TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                      height: 20 / 12,
                    ),
                  ),
                  Text(
                    '${candidate.details}\n',//${candidate.partylist},  //ADD CANDIDATE
                    style: TextStyle(
                      color: Color(0xFF747474),
                      fontFamily: 'Geist',
                      fontSize: 12,
                      height: 20 / 12,
                    ),
                  ),
                ],
              ),
            ),
            // Right arrow button
            Container(
              width: 40,
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
          ],
        ),
      ),
    );
  }
}
