import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'header.dart';

class CandidateSelectionPage extends StatefulWidget {
  final String positionTitle;
  final List<Candidate> candidates;
  final Candidate? initialSelection;

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
  Candidate? _selectedCandidate;

  @override
  void initState() {
    super.initState();
    _selectedCandidate = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double listTopPadding = topPadding + 102;

    String truncatedTitle = widget.positionTitle.length > 15
        ? '${widget.positionTitle.substring(0, 15)}...'
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
                bottom: 100, // Space for the fixed button
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions Text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, left: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Please select one candidate per position. Read the full ',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Geist',
                            color: Color(0xFF404040),
                          ),
                        ),
                        RichText(
                          text: const TextSpan(
                            text: 'Voting Rules',
                            style: TextStyle(
                              color: Color(0xFF404040),
                              fontSize: 14,
                              fontFamily: 'Geist',
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w700,
                            ),
                            children: [
                              TextSpan(
                                text: '. Vote wisely.',
                                style: TextStyle(
                                  color: Color(0xFF404040),
                                  fontSize: 14,
                                  fontFamily: 'Geist',
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Candidate List 
                  widget.candidates.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50.0),
                            child: Text(
                              'No candidates available',
                              style: TextStyle(
                                color: Color(0xFF404040),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: widget.candidates.map((candidate) {
                            final bool isSelected =
                                _selectedCandidate?.name == candidate.name &&
                                _selectedCandidate?.partylist ==
                                    candidate.partylist;
                            final Color backgroundColor = isSelected
                                ? const Color(0xFFDFE3F0)
                                : const Color(0xFFF7F7F7);
                            final Color borderColor = isSelected
                                ? const Color(0xFF5C6AA0)
                                : const Color(0xFFD9D9D9);
                            final Color radioColor = isSelected
                                ? const Color(0xFF5C6AA0)
                                : const Color(0xFFD9D9D9);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCandidate = candidate;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFF7F7F7)
                                                : const Color(0xFFE7E8E9),
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  candidate.college,
                                                  style: const TextStyle(
                                                    color: Color(0xFF747474),
                                                    fontSize: 12,
                                                    fontFamily: 'Geist',
                                                  ),
                                                ),
                                                Text(
                                                  '${candidate.year} Year',
                                                  style: const TextStyle(
                                                    color: Color(0xFF747474),
                                                    fontSize: 12,
                                                    fontFamily: 'Geist',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? radioColor
                                                : const Color(0xFFDFDFE1),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFFAAB3D0)
                                                  : const Color(0xFFD9D9D9),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            candidate.partylist,
                                            style: const TextStyle(
                                              color: Color(0xFF747474),
                                              fontSize: 12,
                                              fontFamily: 'Geist',
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            candidate.name,
                                            style: const TextStyle(
                                              color: Color(0xFF404040),
                                              fontSize: 16,
                                              fontFamily: 'Geist',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: CustomHeader(
                    title: truncatedTitle,
                    onBack: () =>
                        Navigator.pop(context, widget.initialSelection),
                  ),
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
              padding: const EdgeInsets.only(
                left: 25,
                right: 25,
                bottom: 30,
                top: 40,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(1.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedCandidate);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6AA0),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(
                    color: Color(0xFFF8F8F8),
                    fontSize: 14,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w700,
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
