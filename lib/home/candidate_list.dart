import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'list_format.dart';
import 'candidate_profile.dart';

class CandidateWithParty {
  final Candidate candidate;
  final String partylistName;

  CandidateWithParty({required this.candidate, required this.partylistName});
}

class CandidateListPage extends StatelessWidget {
  final String positionTitle;
  final List<Slate> allSlates;

  const CandidateListPage({
    super.key,
    required this.positionTitle,
    required this.allSlates,
  });

  List<CandidateWithParty> _getFilteredCandidates() {
    return allSlates.expand((slate) {
      return slate.candidates
          .where((candidate) => candidate.role == positionTitle)
          .map(
            (candidate) => CandidateWithParty(
              candidate: candidate,
              partylistName: slate.name,
            ),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCandidates = _getFilteredCandidates();

    // Convert candidates to list items
    final candidateItems = filteredCandidates.map((candidateWithParty) {
      return CandidateListItem(
        candidate: candidateWithParty.candidate,
        partylistName: candidateWithParty.partylistName,
      );
    }).toList();

    return ReusableListPage(
      title: positionTitle,
      onBack: () => Navigator.pop(context),
      items: candidateItems,
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
              // Placeholder for Candidate Image
              Container(
                width: 93,
                height: 93,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(16),
                ),
                // Candidate image goes here
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
