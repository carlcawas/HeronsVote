import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'voting_models.dart';
import 'header.dart';

class CandidateSelectionPage extends StatefulWidget {
  final String positionTitle;
  final List<VotingCandidate> candidates;
  final VotingCandidate? initialSelection;
  final bool isProposal; 
  final String? electionType;
  final String? userCollege;

  const CandidateSelectionPage({
    super.key,
    required this.positionTitle,
    required this.candidates,
    this.initialSelection,
    this.isProposal = false,
    this.electionType,
    this.userCollege,
  });

  @override
  State<CandidateSelectionPage> createState() => _CandidateSelectionPageState();
}

class _CandidateSelectionPageState extends State<CandidateSelectionPage> {
  VotingCandidate? _selectedCandidate;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _selectedCandidate = widget.initialSelection;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double listTopPadding = topPadding + 102;

    String truncatedTitle = widget.positionTitle.length > 25
        ? '${widget.positionTitle.substring(0, 25)}...'
        : widget.positionTitle;

    List<VotingCandidate> displayedCandidates = widget.candidates;

    if (widget.electionType == 'college' && widget.userCollege != null) {
      displayedCandidates = displayedCandidates.where((candidate) {
        return candidate.college == widget.userCollege;
      }).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      displayedCandidates = displayedCandidates.where((candidate) {
        final name = candidate.name.toLowerCase();
        final partylist = candidate.partylist.toLowerCase();
        return name.contains(_searchQuery) || partylist.contains(_searchQuery);
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: listTopPadding,
                left: 24,
                right: 24,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Search bar 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        color: Color(0xFF404040),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search name or slate...",
                        hintStyle: TextStyle(
                          fontFamily: 'Geist',
                          color: Colors.grey.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF5C6AA0)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF5C6AA0), width: 1),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, left: 4, right: 4),
                    child: RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          color: Color(0xFF404040),
                          //height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Please select one option from the list. Read the full ', 
                          ),
                          TextSpan(
                            text: 'Voting Rules',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                print('Voting Rules Clicked');
                              },
                          ),
                          const TextSpan(text: '. Vote wisely.'),
                        ],
                      ),
                    ),
                  ),

                  displayedCandidates.isEmpty
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.only(top: 50),
                              child: Text(
                                _searchQuery.isNotEmpty 
                                  ? "No candidates found matching '$_searchQuery'"
                                  : "No options found for your college",
                                style: const TextStyle(color: Colors.grey),
                              )))
                      : Column(
                          children: [
                            if (widget.isProposal) ...[
                              ...displayedCandidates.map((option) {
                                final bool isSelected = _selectedCandidate != null &&
                                    _selectedCandidate!.name == option.name;
                                return _buildProposalOption(option, isSelected);
                              }),
                              
                              _buildProposalAbstainOption(), 
                            ] else ...[
                              ...displayedCandidates.map((candidate) {
                                final bool isSelected =
                                    _selectedCandidate != null &&
                                        _selectedCandidate!.name == candidate.name;
                                return _buildCandidateTile(candidate, isSelected);
                              }),
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 10),
                              _buildAbstainTile(),
                            ]
                          ],
                        ),
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
                Container(height: topPadding, color: Colors.white),
                CustomHeader(
                  title: truncatedTitle,
                  onBack: () => Navigator.pop(context, widget.initialSelection),
                ),
              ],
            ),
          ),

          // Select button
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

  Widget _buildProposalOption(VotingCandidate option, bool isSelected) {
    final colorBg = isSelected ? const Color(0xFFDFE3F0) : const Color(0xFFF7F7F7);
    final colorBorder = isSelected ? const Color(0xFF5C6AA0) : const Color(0xFFE7E8E9);

    return GestureDetector(
      onTap: () => setState(() => _selectedCandidate = option),
      child: Container(
        width: double.infinity, 
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorBorder, width: 1.5),
        ),
        constraints: const BoxConstraints(minHeight: 60), 
        child: Stack(
          children: [
             Padding(
               padding: const EdgeInsets.fromLTRB(20, 18, 50, 18), 
               child: Text(
                option.name,
                style: const TextStyle(
                  color: Color(0xFF404040),
                  fontSize: 16,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                ),
              ),
             ),
             Positioned(
              top: 12,
              right: 12,
              child: Container(
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
              ),
             ),
          ],
        ),
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
                          color: const Color.fromARGB(211, 9, 108, 207),
                          borderRadius: BorderRadius.circular(25),
                          image: (publicUrl != null)
                              ? DecorationImage(
                                  image: NetworkImage(publicUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (publicUrl == null)
                            ? const Icon(Icons.person, size: 30, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            candidate.college.isEmpty ? 'College' : candidate.college,
                            style: const TextStyle(color: Color(0xFF747474), fontSize: 12, fontFamily: 'Geist', fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            candidate.year.isEmpty ? 'Year' : '${candidate.year} Year',
                            style: const TextStyle(color: Color(0xFF747474), fontSize: 12, fontFamily: 'Geist'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    candidate.partylist.isEmpty ? 'Independent' : candidate.partylist,
                    style: const TextStyle(color: Color(0xFF747474), fontSize: 12, fontFamily: 'Geist', fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    candidate.name,
                    style: const TextStyle(color: Color(0xFF404040), fontSize: 18, fontFamily: 'Geist', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 0, top: 0),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF5C6AA0) : const Color(0xFFDFDFE1),
                border: Border.all(color: isSelected ? const Color(0xFFAAB3D0) : const Color(0xFFD9D9D9), width: 2),
              ),
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorBorder, width: 1.5),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Row(
                children: [
                  /*Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: const Color(0xFFE7E8E9), borderRadius: BorderRadius.circular(50)),
                    child: const Icon(Icons.how_to_vote_outlined, color: Color(0xFF747474)),
                  ),*/
                  const SizedBox(width: 12),
                  const Text(
                    'Abstain',
                    style: TextStyle(color: Color(0xFF404040), fontSize: 16, fontFamily: 'Geist', fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 12, 
              right: 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF5C6AA0) : const Color(0xFFDFDFE1),
                  border: Border.all(color: isSelected ? const Color(0xFFAAB3D0) : const Color(0xFFD9D9D9), width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 Widget _buildProposalAbstainOption() {
    final bool isSelected = _selectedCandidate != null && _selectedCandidate!.isAbstain;
    final colorBg = isSelected ? const Color(0xFFDFE3F0) : const Color(0xFFF7F7F7);
    final colorBorder = isSelected ? const Color(0xFF5C6AA0) : const Color(0xFFE7E8E9);

    return GestureDetector(
      onTap: () => setState(() => _selectedCandidate = VotingCandidate.abstain()),
      child: Container(
        width: double.infinity, 
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorBorder, width: 1.5),
        ),
        constraints: const BoxConstraints(minHeight: 60),
        child: Stack(
          children: [
             // Content
             const Padding(
               padding: EdgeInsets.fromLTRB(20, 18, 50, 18),
               child: Text(
                "Abstain",
                style: TextStyle(
                  color: Color(0xFF404040),
                  fontSize: 16,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                ),
              ),
             ),
             // Radio Button
             Positioned(
              top: 12,
              right: 12,
              child: Container(
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
              ),
             ),
          ],
        ),
      ),
    );
  }
}