import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'list_format.dart';
import 'candidate_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CandidateListPage extends StatelessWidget {
  final String positionTitle;

  const CandidateListPage({
    super.key,
    required this.positionTitle,
  });

  @override
  Widget build(BuildContext context) {
    return ReusableListPage(
      title: positionTitle,
      onBack: () => Navigator.pop(context),
      items: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService().getCandidatesByPositionStream(positionTitle),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];

            // TODO: paayos nalang nito, fallback msg kapag wlaang candidate for that position
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No candidates found for ${positionTitle}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            // Map Firestore documents to CandidateListItem widgets
            final candidateItems = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              
              final college = data['college_id'];
              final year = data['year'];

              String fullDetails;

              if (college != null && year != null) {
                fullDetails = '$college - $year Year';
              } else if (college != null) {
                fullDetails = college.toString();
              } else if (year != null) {
                fullDetails = '$year Year';
              } else {
                fullDetails = data['details'] ?? 'No Details';
              }

              // Map Firestore data to Candidate model
              final candidate = Candidate(
                name: data['name'] ?? 'MissingNo?',
                role: data['position'] ?? positionTitle, // Uses the query title as fallback
                details: fullDetails, // e.g. CCIS - 3rd year
                age: data['age']?.toString() ?? 'N/A',
                year: data['year'] ?? 'N/A',
                college: data['college_id'] ?? 'N/A',
                img: data['img'] as String?,
                partylist: data['slate'] ?? 'Independent', 
                advocacy: data['advocacy'] ?? 'No advocacy provided.',
                platform: data['platform'] ?? 'No platform provided.',
              );
              
              return CandidateListItem(
                candidate: candidate,
                partylistName: candidate.partylist,
              );
            }).toList();

            return Column(children: candidateItems);
          },
        ),
      ],
      emptyMessage: 'No candidates found for this position',
    );
  }
}

class CandidateListItem extends StatelessWidget {
  final Candidate candidate;
  final String partylistName;

  const CandidateListItem({
    super.key,
    required this.candidate,
    required this.partylistName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Future.delayed(const Duration(milliseconds: 100), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CandidateProfilePage(
                candidate: Candidate(
                  name: candidate.name,
                  age: candidate.age,
                  year: candidate.year,
                  college: candidate.college,
                  img: candidate.img,
                  partylist: partylistName,
                  advocacy: candidate.advocacy,
                  role: candidate.role,
                  details: candidate.details,
                  platform: candidate.platform,
                ),
              ),
            ),
          );
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 105,
          padding: const EdgeInsets.all(6), //ayusin ko sa figma
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              
            ],

            border: Border.all( //adjust kona rin sa figma
              color: const Color(0xFFEEEEEE),
              width: 0.5,
            ),

          ),
          child: Row(
            children: [
              // Candidate Image
              Container(
                width: 93,
                height: 93,
                margin: const EdgeInsets.only(right: 15),
                child: _buildSupabaseImageWidget(
                  filePath: candidate.img,
                  width: 93,
                  height: 93,
                  borderRadius: 16,
                  iconSize: 45,
                ),
              ),

              // Candidate Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        color: Color(0xFF404040),
                        fontSize: 16,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      candidate.details,
                      style: TextStyle(
                        color: const Color(0xFF404040).withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partylistName,
                      style: TextStyle(
                        color: const Color(0xFF404040).withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
      color: const Color(0xFFD9D9D9), // Placeholder background
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    ),
  );
}