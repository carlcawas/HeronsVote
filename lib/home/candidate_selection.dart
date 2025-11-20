import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'voting_models.dart';
import 'header.dart';

class CandidateSelectionPage extends StatefulWidget {
  final String positionTitle;
  final List<VotingCandidate> candidates;
  final VotingCandidate? initialSelection;

  const CandidateSelectionPage({
    super.key,
    required this.positionTitle,
    required this.candidates,
    this.initialSelection,
  });

  @override
  State<CandidateSelectionPage> createState() => _CandidateSelectionPageState();
}

class _CandidateSelectionPageState extends State<CandidateSelectionPage> {
  VotingCandidate? _selectedCandidate;

  @override
  void initState() {
    super.initState();
    _selectedCandidate = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double listTopPadding = topPadding + 102;

    String truncatedTitle = widget.positionTitle.length > 25
        ? '${widget.positionTitle.substring(0, 25)}...'
        : widget.positionTitle;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: listTopPadding,
                left: 25,
                right: 25,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions Text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, left: 5),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          color: Color(0xFF404040),
                          height: 1.5, // Adds a little spacing between lines
                        ),
                        children: [
                          const TextSpan(
                            text: 'Please select one candidate per position.\nRead the full ',
                          ),
                          TextSpan(
                            text: 'Voting Rules',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Handle Voting Rules Click
                                print('Voting Rules Clicked'); 
                                // Navigator.push(context, MaterialPageRoute(...));
                              },
                          ),
                          const TextSpan(
                            text: '. Vote wisely.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Candidate List 
                  widget.candidates.isEmpty
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text("No candidates found")))
                  : Column(
                      children: [
                        ...widget.candidates.map((candidate) {
                          final bool isSelected =
                              _selectedCandidate != null &&
                                  _selectedCandidate!.name ==
                                      candidate.name;
                          return _buildCandidateTile(candidate, isSelected);
                        }),

                        // ABSTAIN OPTION
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        _buildAbstainTile(),
                      ],
                    ),
                ],
              ),
            ),
          ),

          //header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(height: topPadding, color: Colors.white),
                CustomHeader(
                  title: truncatedTitle,
                  onBack: () =>
                      Navigator.pop(context, widget.initialSelection),
                ),
              ],
            ),
          ),

          //Select button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 40, 25, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.0), Colors.white],
                ),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedCandidate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6AA0),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(
                      color: Color(0xFFF8F8F8),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Geist'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateTile(VotingCandidate candidate, bool isSelected) {
    final colorBg = isSelected ? const Color(0xFFDFE3F0) : const Color(0xFFF7F7F7);
    final colorBorder = isSelected ? const Color(0xFF5C6AA0) : const Color(0xFFD9D9D9);
    
    String? publicUrl;
    if (candidate.img != null && candidate.img!.isNotEmpty) {
      try {
        publicUrl = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(candidate.img!);
      } catch (e) {
        publicUrl = null;
      }
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedCandidate = candidate),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorBorder, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7E8E9),
                          borderRadius: BorderRadius.circular(25),
                          image: (publicUrl != null)
                              ? DecorationImage(
                                  image: NetworkImage(publicUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (publicUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            candidate.college.isEmpty ? 'College' : candidate.college,
                            style: const TextStyle(
                              color: Color(0xFF747474),
                              fontSize: 12,
                              fontFamily: 'Geist',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            candidate.year.isEmpty ? 'Year' : '${candidate.year} Year',
                            style: const TextStyle(
                              color: Color(0xFF747474),
                              fontSize: 12,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),

                  // Slate Name
                  Text(
                    candidate.partylist.isEmpty ? 'Independent' : candidate.partylist,
                    style: const TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  
                  const SizedBox(height: 4),

                  // Candidate Name
                  Text(
                    candidate.name,
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 18,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // selection
            Container(
              margin: const EdgeInsets.only(left: 10, top: 15),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF5C6AA0) : const Color(0xFFDFDFE1),
                border: Border.all(
                  color: isSelected ? const Color(0xFFAAB3D0) : const Color(0xFFD9D9D9),
                  width: 2,
                ),
              ),
              child: isSelected 
                ? const Center(
                    child: Icon(Icons.check, size: 14, color: Colors.white),
                  ) 
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbstainTile() {
    final bool isSelected = _selectedCandidate != null && _selectedCandidate!.isAbstain;
    final colorBg = isSelected ? const Color(0xFFDFE3F0) : const Color(0xFFF7F7F7);
    final colorBorder = isSelected ? const Color(0xFF5C6AA0) : const Color(0xFFD9D9D9);

    return GestureDetector(
      onTap: () => setState(() => _selectedCandidate = VotingCandidate.abstain()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: const Color(0xFFE7E8E9),
                  borderRadius: BorderRadius.circular(50)),
              child: const Icon(Icons.how_to_vote_outlined,
                  color: Color(0xFF747474)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Abstain',
                style: TextStyle(
                    color: Color(0xFF404040),
                    fontSize: 16,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF5C6AA0)
                    : const Color(0xFFDFDFE1),
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFFAAB3D0)
                        : const Color(0xFFD9D9D9),
                    width: 2),
              ),
              child: isSelected 
                ? const Center(
                    child: Icon(Icons.check, size: 14, color: Colors.white),
                  ) 
                : null,
            ),
          ],
        ),
      ),
    );
  }
}
