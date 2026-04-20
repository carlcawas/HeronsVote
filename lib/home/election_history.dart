import 'package:flutter/material.dart';
import 'header.dart'; 
import 'results.dart'; 

class ElectionHistoryPage extends StatefulWidget {
  final String uid;
  final String? userCollege;

  const ElectionHistoryPage({super.key, required this.uid, this.userCollege});

  @override
  State<ElectionHistoryPage> createState() => _ElectionHistoryPageState();
}

class _ElectionHistoryPageState extends State<ElectionHistoryPage> {
  static const Color _bgColor = Color(0xFFF7F7F7);
  static const Color _textColor = Color(0xFF404040);
  static const Color _subTextColor = Color(0xFF747474);
  static const Color _dividerColor = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 130, 
                left: 24,
                right: 24,
                bottom: 100, 
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Showing a 3-year historical record of university-wide and college-level student elections.",
                    style: TextStyle(
                      color: _subTextColor,
                      fontSize: 14,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  //University Wide Section
                  _buildSection(
                    context,
                    label: "University-Wide Elections",
                    elections: [
                      _ElectionItem(
                        title: "AY 2025 University Student Council Elections",
                        data: {
                          'id': 'usc-2025',
                          'type': 'university',
                          'title':
                              'AY 2025 University Student Council Elections',
                          'ongoing': false,
                        },
                      ),
                      _ElectionItem(
                        title: "AY 2024 University Student Council Elections",
                        data: {
                          'id': 'usc-2024',
                          'type': 'university',
                          'title':
                              'AY 2024 University Student Council Elections',
                          'ongoing': false,
                        },
                      ),
                      _ElectionItem(
                        title: "AY 2023 University Student Council Elections",
                        data: {
                          'id': 'usc-2023',
                          'type': 'university',
                          'title':
                              'AY 2023 University Student Council Elections',
                          'ongoing': false,
                        },
                      ),
                    ],
                  ),

                  // College Specific Section
                  _buildSection(
                    context,
                    label: "College-Specific Elections",
                    elections: [
                      _ElectionItem(
                        title: "AY 2025 College Student Council Election",
                        data: {
                          'id': 'csc-2025',
                          'type': 'local',
                          'title': 'AY 2025 College Student Council Election',
                          'ongoing': false,
                          'college_id': widget.userCollege,
                        },
                      ),
                      _ElectionItem(
                        title: "AY 2024 College Student Council Election",
                        data: {
                          'id': 'csc-2024',
                          'type': 'local',
                          'title': 'AY 2024 College Student Council Election',
                          'ongoing': false,
                          'college_id': widget.userCollege,
                        },
                      ),
                      _ElectionItem(
                        title: "AY 2023 College Student Council Election",
                        data: {
                          'id': 'csc-2023',
                          'type': 'local',
                          'title': 'AY 2023 College Student Council Election',
                          'ongoing': false,
                          'college_id': widget.userCollege,
                        },
                      ),
                    ],
                  ),

                  // Proposals Section
                  _buildSection(
                    context,
                    label: "Proposal Elections",
                    elections: [
                      _ElectionItem(
                        title:
                            "2025 Proposed Amendment to the COSEL Constitution",
                        data: {
                          'id': 'prop-2025',
                          'type': 'proposal',
                          'title':
                              '2025 Proposed Amendment to the COSEL Constitution',
                          'ongoing': false,
                        },
                      ),
                      _ElectionItem(
                        title: "AY 2024 Student Handbook Revision Plebiscite",
                        data: {
                          'id': 'prop-2024',
                          'type': 'proposal',
                          'title': 'AY 2024 Student Handbook Revision',
                          'ongoing': false,
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          //TOP HEADER 
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: CustomHeader(
                  title: "Results",
                  onBack: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.0), Colors.white],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String label,
    required List<_ElectionItem> elections,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textColor, 
            fontSize: 14,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD9D9D9), width: 1.0),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: elections.asMap().entries.map((entry) {
              final isLast = entry.key == elections.length - 1;
              return Column(
                children: [
                  _buildElectionTile(context, entry.value),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFD9D9D9),
                     
                      indent: 10,
                      endIndent: 10,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildElectionTile(BuildContext context, _ElectionItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  HistoryResultPage(uid: widget.uid, electionData: item.data),
            ),
          );
        },
        child: Padding(
          // Text padding inside the box
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: const TextStyle(
                      color: _subTextColor,
                      fontSize: 13,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryResultPage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> electionData;

  const HistoryResultPage({
    super.key,
    required this.uid,
    required this.electionData,
  });

  @override
  State<HistoryResultPage> createState() => _HistoryResultPageState();
}

class _HistoryResultPageState extends State<HistoryResultPage> {
  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: topPadding + 26),
              child: ElectionResultPage(
                uid: widget.uid,
                electionData: widget.electionData,
                onBack: null, 
              ),
            ),
          ),

          // HEADER 
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: CustomHeader(
                  title:
                      widget.electionData['title'] ??
                      widget.electionData['name'] ??
                      'Results',
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElectionItem {
  final String title;
  final String? subtitle;
  final Map<String, dynamic> data;

  const _ElectionItem({required this.title, this.subtitle, required this.data});
}
