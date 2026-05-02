import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'header.dart';
import 'results.dart';

class ElectionHistoryPage extends StatelessWidget {
  final String uid;

  const ElectionHistoryPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('archives').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Failed to load archives: ${snapshot.error}'),
                    ),
                  );
                }

                final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [
                  ...(snapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[]),
                ];
                docs.sort((a, b) {
                  final aTs = _pickArchiveTimestamp(a.data());
                  final bTs = _pickArchiveTimestamp(b.data());
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });

                final university = docs.where(_isUniversityArchive).toList();
                final college = docs.where(_isCollegeArchive).toList();
                final proposal = docs.where(_isProposalArchive).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No archived elections yet.'));
                }

                return SingleChildScrollView(
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
                        'Showing a 3-year historical record of university-wide and college-level student elections.',
                        style: TextStyle(
                          color: Color(0xFF747474),
                          fontSize: 14,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        label: 'University-Wide Elections',
                        docs: university,
                      ),
                      _buildSection(
                        context,
                        label: 'College-Specific Elections',
                        docs: college,
                      ),
                      _buildSection(
                        context,
                        label: 'Proposal Elections',
                        docs: proposal,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: CustomHeader(
                  title: 'Results',
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
                    colors: [Colors.white.withValues(alpha: 0.0), Colors.white],
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
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    if (docs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF404040),
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
            children: docs.asMap().entries.map((entry) {
              final isLast = entry.key == docs.length - 1;
              final doc = entry.value;
              return Column(
                children: [
                  _buildArchiveTile(context, doc),
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

  Widget _buildArchiveTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = _title(data, doc.id);
    final electionData = _toResultElectionData(doc);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoryResultPage(
                uid: uid,
                electionData: electionData,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF404040),
                fontSize: 14,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _toResultElectionData(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final String originalCollection =
        (data['originalCollection'] ?? '').toString().toLowerCase();
    final String collegeId = (data['college_id'] ?? '').toString();
    final String type = originalCollection == 'proposals'
        ? 'proposal'
        : (collegeId.isEmpty ? 'university' : 'college');

    return {
      ...data,
      'id': (data['election_id'] ?? doc.id).toString(),
      'archiveId': doc.id,
      'sourceCollection': 'archives',
      'type': type,
      'ongoing': false,
      'publishStatus': 'Published',
      'title': data['name'] ?? data['title'] ?? 'Archived Election',
    };
  }

  static String _title(Map<String, dynamic> data, String fallbackId) {
    return (data['title'] ??
            data['name'] ??
            data['electionTitle'] ??
            data['election_name'] ??
            fallbackId)
        .toString();
  }

  static bool _isProposalArchive(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final originalCollection =
        (data['originalCollection'] ?? '').toString().toLowerCase();
    final modifiedIn = (data['modifiedIn'] ?? '').toString().toLowerCase();
    return originalCollection == 'proposals' || modifiedIn == 'proposal';
  }

  static bool _isCollegeArchive(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    if (_isProposalArchive(d)) return false;
    final data = d.data();
    final collegeId = (data['college_id'] ?? '').toString().trim();
    return collegeId.isNotEmpty;
  }

  static bool _isUniversityArchive(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    if (_isProposalArchive(d)) return false;
    return !_isCollegeArchive(d);
  }

  static Timestamp? _pickArchiveTimestamp(Map<String, dynamic> data) {
    final dynamic ts =
        data['archiveApprovedAt'] ??
        data['archivedAt'] ??
        data['end'] ??
        data['closedAt'] ??
        data['updated_at'];
    return ts is Timestamp ? ts : null;
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
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.0),
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
