import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'slates_details.dart';
import 'header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SlateListPage extends StatelessWidget {
  final String electionId;
  const SlateListPage({Key? key, required this.electionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final FirebaseService _service = FirebaseService();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _service.getSlatesStream(electionId),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Error loading slates'));
              }
              if (!snap.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final slates =
                  snap.data!.docs.map(Slate.fromFirestore).toList();
              if (slates.isEmpty) {
                return Center(child: Text('No slates found'));
              }

              return ListView.builder(
                padding: EdgeInsets.only(
                  top: topPadding + 102,
                  left: 25,
                  right: 25,
                  bottom: 22,
                ),
                itemCount: slates.length,
                itemBuilder: (_, i) => SlateListItem(
                  slate: slates[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SlateDetailsPage(slate: slates[i]),
                    ),
                  ),
                ),
              );
            },
          ),

          // Header 
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  height: topPadding,
                  color: Colors.white,
                ),

                // Header 
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
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: CustomHeader(
                    title: 'Slates',
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


class SlateListItem extends StatelessWidget {
  final Slate slate;
  final VoidCallback onTap;

  const SlateListItem({
    Key? key,
    required this.slate,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 105,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left placeholder image area
              Container(
                width: 131,
                height: 93,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  image: slate.imgPath != null
                      ? DecorationImage(
                          image: NetworkImage(
                            Supabase.instance.client.storage
                                .from('images')
                                .getPublicUrl(slate.imgPath!),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 15),
              // Slate Name
              Expanded(
                child: Text(
                  slate.name,
                  style: const TextStyle(
                    color: Color(0xFF404040),
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Right arrow button
              Container(
                width: 40,
                height: 93,
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
      ),
    );
  }
}

// Slate model
class Slate {
  final String id;
  final String name;
  final String slogan;
  final String? imgPath;
  final String advocacy;
  final String platform;
  final List<Candidate> candidates;

  Slate({
    required this.id,
    required this.name,
    required this.slogan,
    this.imgPath,
    required this.advocacy,
    required this.platform,
    required this.candidates,
  });

  factory Slate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Slate(
      id: doc.id,
      name: data['name'] ?? 'Nameless Slate',
      slogan: data['slogan'] ?? 'No slogan published',
      imgPath: data['img'] ?? 'assets/accounts.svg',
      advocacy: data['advocacy'] ?? 'No advocacy published.',
      platform: data['platform'] ?? 'No platform published.',
      candidates: (data['candidates'] as List<dynamic>?)
              ?.map((c) => Candidate.fromMap(c))
              .toList() ??
          [],
    );
  }
}

// Candidate model
class Candidate {
  final String name;
  final String role;
  final String party;
  final String details;    // course & year
  final String? imgPath;

  Candidate({
    required this.name,
    required this.role,
    required this.party,
    required this.details,
    this.imgPath,
  });

  factory Candidate.fromMap(Map<String, dynamic> map) {
    return Candidate(
      name: map['name'] ?? '',
      role: map['position'] ?? map['role'] ?? '',
      party: map['party'] ?? 'No Party',
      details: map['details'] ?? 'No Details',
      imgPath: map['img'],
    );
  }
}
