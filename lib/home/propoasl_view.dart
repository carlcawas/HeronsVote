import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'header.dart';

class ProposalViewPage extends StatelessWidget {
  final Proposal proposal;

  const ProposalViewPage({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: proposal.title,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compile all available proposal details
                    ..._buildProposalSections(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProposalSections() {
    final List<Widget> sections = [];

    // Add summary if available
    if (proposal.summary?.isNotEmpty == true) {
      sections.add(
        ExpandableSection(
          title: 'Summary',
          content: proposal.summary!,
        ),
      );
    }

    // Add rationale if available
    if (proposal.rationale?.isNotEmpty == true) {
      sections.add(
        ExpandableSection(
          title: 'Rationale',
          content: proposal.rationale!,
        ),
      );
    }

    // Add comparison if available
    if (proposal.comparison?.isNotEmpty == true) {
      sections.add(
        ExpandableSection(
          title: 'Comparison',
          content: proposal.comparison!,
        ),
      );
    }

    // Add resources plan if available
    if (proposal.resources?.isNotEmpty == true) {
      sections.add(
        ExpandableSection(
          title: 'Resources',
          content: proposal.resources!,
        ),
      );
    }
    // If no sections were added, show a message
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
          if (widget.content.length > 150)
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