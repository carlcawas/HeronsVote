import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class TurnoutDebugData {
  final int totalVoters = 475;
  final int totalVotesCast = 378;

  final List<VoteTurnout> turnouts = [
    VoteTurnout("1st year", 112, 140),
    VoteTurnout("2nd year", 91, 130),
    VoteTurnout("3rd year", 99, 110),
    VoteTurnout("4th year", 76, 95),
    VoteTurnout("CCSE", 50, 50),
  ];

  double get totalPercentage =>
      totalVoters == 0 ? 0 : totalVotesCast / totalVoters;
}

class VoteTurnout {
  final String label;
  final int cast;
  final int total;
  double get percentage => total == 0 ? 0 : cast / total;

  VoteTurnout(this.label, this.cast, this.total);
}

class PositionResultDebugData {
  final String positionTitle;
  final List<CandidateResult> candidates;
  PositionResultDebugData(this.positionTitle, this.candidates);
}

class CandidateResult {
  final String name;
  final int votes;
  final bool isWinner;
  CandidateResult(this.name, this.votes, {this.isWinner = false});
}

final turnoutData = TurnoutDebugData();

final List<PositionResultDebugData> resultsData = [
  PositionResultDebugData("Chairperson", [
    CandidateResult("Rhic Ruzel H. Reyes", 50, isWinner: true),
    CandidateResult("Jane Doe", 30),
    CandidateResult("Abstain", 19),
  ]),
  PositionResultDebugData("Vice Chairperson", [
    CandidateResult("John Smith", 55, isWinner: true),
    CandidateResult("Rhic Ruzel H. Reyes", 25),
    CandidateResult("Abstain", 10),
  ]),
];

class ElectionResultPage extends StatefulWidget {
  const ElectionResultPage({super.key});

  @override
  State<ElectionResultPage> createState() => _ElectionResultPageState();
}

class _ElectionResultPageState extends State<ElectionResultPage> {
  String _currentState = 'Ongoing';
  bool _isExpanded = false;
  bool _isEndedTurnoutVisible = false;

  final Color _bgColor = const Color(0xFFF7F7F7);
  final Color _textColor = const Color(0xFF404040);
  final Color _subTextColor = const Color(0xFF747474);
  final Color _blueHighlight = const Color(0xFF74B6F9);
  final Color _yellowHighlight = const Color(0xFFFFF7C4);
  final Color _yellowBorder = const Color(0xFFFFEB66);
  final Color _redAccent = const Color(0xFFED6C6A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentState,
                icon: const Icon(Icons.accessibility_new_rounded),
                items: <String>['Ongoing', 'Ended'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _currentState = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: _currentState == 'Ongoing'
            ? _buildOngoingView()
            : _buildEndedView(),
      ),
    );
  }

  //progress bar tunrout container / box
  Widget _buildBarsOnly() {
    final int totalItems = turnoutData.turnouts.length;
    final int itemsToShow = _isExpanded
        ? totalItems
        : (totalItems > 4 ? 4 : totalItems);
    final bool showSeeMore = totalItems > 4;

    return Column(
      children: [
        ...turnoutData.turnouts.take(itemsToShow).map(
              (data) => Padding(
                padding: const EdgeInsets.only(bottom: 0.0),
                child: _buildTurnoutProgressBar(data),
              ),
            ),
        if (showSeeMore)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
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
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // pie chart area
  Widget _buildPieAndLegend() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            height: 156,
            width: 156,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: 2,
                child: CircularPercentIndicator(
                  radius: 68.0,
                  lineWidth: 136.0,
                  percent: turnoutData.totalPercentage,
                  backgroundColor: _redAccent,
                  progressColor: _blueHighlight,
                  circularStrokeCap: CircularStrokeCap.butt,
                  animation: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildSummaryCardGroup(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rating",
                      style: TextStyle(
                        color: _subTextColor,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Geist',
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "80%",
                      style: TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Geist',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //ongoing state
  Widget _buildOngoingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Voter Turnout",
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: _subTextColor,
                        fontSize: 14,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        const TextSpan(text: "Total: "),
                        TextSpan(
                          text:
                              "${turnoutData.totalVotesCast}/${turnoutData.totalVoters}",
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 12,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildBarsOnly(),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildPieAndLegend(),

        const SizedBox(height: 30),
        Center(
          child: Text(
            "Ongoing election, results not published yet.",
            style: TextStyle(
              color: _subTextColor,
              fontSize: 16,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  //ended
  Widget _buildEndedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 16,
            left: 22,
            right: 22,
          ),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(20),
             border: Border.all(
                    color: const Color(0xFFD9D9D9),
                    width: 1.0,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CSC Election",
                style: TextStyle(
                  color: _textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "(S.Y. 2025-2026)",
                style: TextStyle(
                  color: _subTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Published on: October 2, 2025",
                style: TextStyle(
                  color: _subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // DROPDOWN CONTAINER 
        Container(
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEndedTurnoutVisible = !_isEndedTurnoutVisible;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFECECEC),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isEndedTurnoutVisible
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: _textColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Voter Turnout",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: _subTextColor,
                            fontSize: 14,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            const TextSpan(text: "Total:  "),
                            TextSpan(
                              text:
                                  "${turnoutData.totalVotesCast}/${turnoutData.totalVoters}",
                              style: TextStyle(
                                color: _textColor,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Content: bars
              if (_isEndedTurnoutVisible)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      _buildBarsOnly(), 
                    ],
                  ),
                ),
            ],
          ),
        ),

        //Pie Chart
        if (_isEndedTurnoutVisible) ...[
          const SizedBox(height: 12),
          _buildPieAndLegend(),
        ],

        const SizedBox(height: 24),

        // Results List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: resultsData.length,
          itemBuilder: (context, index) {
            return _buildPositionResultSection(
              resultsData[index],
              showHeader: index == 0,
            );
          },
        ),
      ],
    );
  }

  
  Widget _buildTurnoutProgressBar(VoteTurnout data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;

          const TextStyle textStyle = TextStyle(
            color: Color(0xFF404040),
            fontSize: 12,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          );

          final TextPainter percentPainter = TextPainter(
            text: TextSpan(
              text: "${(data.percentage * 100).toStringAsFixed(0)}%",
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final TextPainter fractionPainter = TextPainter(
            text: TextSpan(
              text: "${data.cast}/${data.total}",
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final double percentTextWidth = percentPainter.width;
          final double fractionTextWidth = fractionPainter.width;
          const double gap = 16.0;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: data.percentage),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, animatedPercentage, child) {
              final double currentBarEnd = totalWidth * animatedPercentage;
              final double maxAllowedRight =
                  totalWidth - percentTextWidth - gap;

              final double actualRightEdge = (currentBarEnd < maxAllowedRight)
                  ? currentBarEnd
                  : maxAllowedRight;

              final double finalLeftPosition =
                  (actualRightEdge - fractionTextWidth) > 0
                      ? (actualRightEdge - fractionTextWidth)
                      : 0;

              return Container(
                height: 34,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFFECECEC),
                    width: 3.0,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      width: currentBarEnd,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF74B6F9),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(data.label, style: textStyle),
                      ),
                    ),
                    Positioned(
                      left: finalLeftPosition - 10,
                      child: SizedBox(
                        height: 34,
                        child: Center(
                          child: Text(
                            "${data.cast}/${data.total}",
                            style: textStyle,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(data.percentage * 100).toStringAsFixed(0)}%",
                          style: textStyle,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCardGroup() {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.circle, color: _blueHighlight, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "Voted",
                    style: TextStyle(
                      color: _subTextColor,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  "${(turnoutData.totalPercentage * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: _textColor,
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFD9D9D9),
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.circle, color: _redAccent, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "Did not vote",
                    style: TextStyle(
                      color: _subTextColor,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Geist',
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  "${((1.0 - turnoutData.totalPercentage) * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Geist',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  //Result under ung may positions
  Widget _buildPositionResultSection(
    PositionResultDebugData data, {
    bool showHeader = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                data.positionTitle,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (showHeader)
              SizedBox(
                width: 73,
                child: Text(
                  "No. of votes",
                  style: TextStyle(color: _subTextColor, fontSize: 12, fontFamily: 'Geist', fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ...data.candidates.map(
          (candidate) => _buildCandidateResultCard(candidate),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  // eto ung mga candidates ung mga name and no of votes
  Widget _buildCandidateResultCard(CandidateResult candidate) {
    final Color cardColor = candidate.isWinner ? _yellowHighlight : _bgColor;
    final BoxBorder border = candidate.isWinner
        ? Border.all(color: _yellowBorder, width: 2)
        : Border.all(color: const Color(0xFFECECEC), width: 2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: border,
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                candidate.name,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 44,
            width: 73,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: border,
            ),
            alignment: Alignment.center,
            child: Text(
              candidate.votes.toString(),
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}