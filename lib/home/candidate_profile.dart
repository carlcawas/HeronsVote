import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'header.dart';

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

    return Container(
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

//Main page
class CandidateProfilePage extends StatelessWidget {
  final Candidate candidate;

  const CandidateProfilePage({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    String truncatedName = candidate.name.split(' ').take(2).join(' ') + '...';

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (25 * 2);

    final nameWidth = (availableWidth * 0.80) - 12;
    final ageWidth = availableWidth * 0.20;
    final yearWidth = availableWidth * 0.30;
    final collegeWidth = (availableWidth * 0.70) - 12;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: truncatedName,
              onBack: () => Navigator.pop(context),
            ),
            //contents
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 344,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(20),
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
                                  candidate.name,
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
                                  candidate.age,
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
                                  candidate.year,
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
                                  candidate.college,
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
                              candidate.partylist,
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
                      content: candidate.advocacy,
                    ),

                    // Platform Section
                    ExpandableSection(
                      title: 'Platform',
                      content: candidate.platform,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}