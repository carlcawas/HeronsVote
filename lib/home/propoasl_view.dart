import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'header.dart';

class ProposalViewPage extends StatefulWidget {
  final Proposal proposal;

  const ProposalViewPage({super.key, required this.proposal});

  @override
  State<ProposalViewPage> createState() => _ProposalViewPageState();
}

class _ProposalViewPageState extends State<ProposalViewPage> {
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
                  // Compile all available proposal details
                  ..._buildProposalSections(),
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
                    title: widget.proposal.title,
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

  List<Widget> _buildProposalSections() {
    final List<Widget> sections = [];
    //all if are adding only that pert if there is given part // CAN DELETE IF UPON CREATION ITS REQUIRED
    if (widget.proposal.summary?.isNotEmpty == true) {
      sections.add(
        ExpandableSection(
          title: 'Summary',
          content: widget.proposal.summary!,
        ),
      );
    }

    if (widget.proposal.rationale?.isNotEmpty == true) {
      sections.add(
        ExpandableSection(
          title: 'Rationale',
          content: widget.proposal.rationale!,
        ),
      );
    }

    if (widget.proposal.comparison?.isNotEmpty == true) {
      sections.add(
        ExpandableSection(
          title: 'Comparison',
          content: widget.proposal.comparison!,
        ),
      );
    }

    if (widget.proposal.resources?.isNotEmpty == true) {
      sections.add(
        ExpandableSection(
          title: 'Resources',
          content: widget.proposal.resources!,
        ),
      );
    }
    // If no sections were added
    if (sections.isEmpty) {
      sections.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 25),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'No proposal details available.',
            style: TextStyle(
              color: Color(0xFF404040),
              fontSize: 14,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return sections;
  }
}

//expand if long
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

class _ExpandableSectionState extends State<ExpandableSection> {
  bool _isExpanded = false;
  final int collapsedMaxLines = 3;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (25 * 2);

    return Container(
      width: availableWidth,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 25),
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
              fontSize: 18,
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