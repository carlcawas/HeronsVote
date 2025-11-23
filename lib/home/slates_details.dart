import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'header.dart';
import 'slates_list.dart' show Slate, Candidate; 

import 'package:supabase_flutter/supabase_flutter.dart';
import 'slates_list.dart';

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
                top: topPadding + 102,
                left: 25,
                right: 25,
                bottom: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  StreamBuilder<QuerySnapshot>(
                    stream: slateDocRef.collection('slatePlatvocacy').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Text("Error loading info");
                      if (!snapshot.hasData) return const CircularProgressIndicator();

                      String advocacy = "No advocacy details provided.";
                      String platform = "No platform details provided.";

                      if (snapshot.data!.docs.isNotEmpty) {
                        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                        advocacy = data['advocacy'] ?? advocacy;
                        platform = data['platform'] ?? platform;
                      }

                      return Column(
                        children: [
                          DetailsCard(
                            title: 'Slate Advocacy',
                            description: advocacy,
                          ),
                          const SizedBox(height: 17),
                          DetailsCard(
                            title: 'Slate Platform',
                            description: platform,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 17),

                  StreamBuilder<QuerySnapshot>(
                    stream: slateDocRef.collection('candidates').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Text("Error loading candidates");
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text("No candidates found in this slate.");
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final candidate = Candidate.fromMap(data);

                          return CandidateListItem(candidate: candidate);
                        }).toList(),
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

class DetailsCard extends StatefulWidget { //collapsible cards (advocacy/platform)
  final String title;
  final String description;

  const DetailsCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<DetailsCard> createState() => _DetailsCardState();
}

class _DetailsCardState extends State<DetailsCard> {
  bool _isContentExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E8E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ROW ---
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // description
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: double.infinity, // Forces layout width calculation
                child: Text(
                  key: ValueKey("desc_${widget.title}_$_isContentExpanded"),
                  widget.description,
                  maxLines: _isContentExpanded ? null : 3,
                  overflow: _isContentExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Align( //see more
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CandidateListItem extends StatelessWidget { //candidate list
  final Candidate candidate;

  const CandidateListItem({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 114,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
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

            Expanded(
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