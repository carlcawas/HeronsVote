
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firebase_service.dart';
import 'package:heronsvote/model/turnout_model.dart';
import 'package:flutter/rendering.dart';

class ElectionResultPage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> electionData;
  final VoidCallback? onBack;

  const ElectionResultPage({
    super.key,
    required this.uid,
    required this.electionData,
    this.onBack,
  });

  @override
  State<ElectionResultPage> createState() => _ElectionResultPageState();
}

class _ElectionResultPageState extends State<ElectionResultPage> {
  bool _isExpanded = false;
  bool _isEndedTurnoutVisible = true;
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  
  late Future<List<Map<String, dynamic>>> _resultsFuture;

  late Future<TurnoutStats> _turnoutFuture;

  // Colors
  final Color _bgColor = const Color(0xFFF7F7F7);
  final Color _textColor = const Color(0xFF404040);
  final Color _subTextColor = const Color(0xFF747474);
  final Color _blueHighlight = const Color(0xFF74B6F9);
  final Color _yellowHighlight = const Color(0xFFFFF7C4);
  final Color _yellowBorder = const Color(0xFFFFEB66);
  final Color _redAccent = const Color(0xFFED6C6A);

  @override
  void initState() {
    super.initState();
    final service = FirebaseService(); // Create instance or use a singleton
    
    _turnoutFuture = service.getTurnoutDataStream(
      electionId: widget.electionData['id'],
      electionType: widget.electionData['type'] ?? 'local',
      userCollege: widget.electionData['college_id'],
    );

    _resultsFuture = service.getElectionDataStream(
      electionId: widget.electionData['id'],
      electionType: widget.electionData['type'] ?? 'local',
    );

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }


  String _computeAcademicYear(Timestamp? startTimestamp) {
    if (startTimestamp == null) return "(Date TBD)";

    DateTime startDate = startTimestamp.toDate();
    int month = startDate.month;
    int year = startDate.year;

    // Academic Year Logic: Sept-July means August (8) starts the new year.
    int startYear = (month >= 8) ? year : year - 1;
    int endYear = startYear + 1;

    return "(S.Y. $startYear-$endYear)";
  }

  @override
  Widget build(BuildContext context) {
    final bool isOngoing = widget.electionData['ongoing'] ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      /*appBar: AppBar(
        backgroundColor: Colors.white,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          isOngoing ? "Live Updates" : "Election Results",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
      ),*/

      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      
      // WRAP IN ANIMATED SLIDE
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut, // Smooth slide motion
        
        // Offset(x, y): 
        // 0,0 = Normal position
        // 0,3 = Move down by 300% of its height (hides it well below screen)
        offset: _isFabVisible ? Offset.zero : const Offset(0, 3.0), 
        
        child: FloatingActionButton(
          onPressed: widget.onBack ?? () => Navigator.pop(context),
          backgroundColor: Color(0xFF5C6AA0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF354372)),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFF8F8F8)),
        ),
      ),

      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_isFabVisible) setState(() => _isFabVisible = false);
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isFabVisible) setState(() => _isFabVisible = true);
            }
            return true;
          },

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildElectionHeader(),
                const SizedBox(height: 20),

                // Use FutureBuilder to handle the async data fetching
                FutureBuilder<TurnoutStats>(
                  future: _turnoutFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(color: _blueHighlight),
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      final fallbackStats = TurnoutStats(
                        breakdown: {},
                        groupTotalVoters: {}, // <--- ADD THIS LINE
                        totalVotesCast: 0,
                        totalVerifiedVoters: 1,
                      );

                      return Column(
                        children: [
                          isOngoing
                              ? _buildOngoingView(fallbackStats)
                              : _buildEndedView(fallbackStats),
                          const SizedBox(height: 20),
                          Text(
                            "Error fetching live data. Showing stored data fallback if available.",
                            style: TextStyle(color: _redAccent, fontSize: 14),
                          ),
                        ],
                      );
                    }

                    final stats = snapshot.data!;
                    return isOngoing
                        ? _buildOngoingView(stats)
                        : _buildEndedView(stats);
                  },
                ),
              ],
            ),
          ),
        ),
      )
    
    );
  }

  Widget _buildElectionHeader() {
    final title =
        widget.electionData['title'] ??
        widget.electionData['name'] ??
        'Election Name';

    final Timestamp? startTimestamp =
        widget.electionData['start'] as Timestamp?;

    final String academicYear = _computeAcademicYear(startTimestamp);

    String startDate = "Date TBD";

    if (startTimestamp != null) {
      final DateTime date = startTimestamp.toDate();
      const List<String> months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final String monthName = months[date.month - 1];
      startDate = "Started in: $monthName ${date.day}, ${date.year}";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            academicYear,
            style: TextStyle(
              color: _subTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            startDate,
            style: TextStyle(
              color: _subTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildOngoingView(TurnoutStats stats) {
    final List<Map<String, dynamic>> turnoutList = stats.breakdown.entries.map((
      e,
    ) {
      final int castCount = e.value;
      final String label = e.key;

      final int groupTotal = stats.groupTotalVoters[label] ?? 1;

      return {
        'label': label,
        'cast': castCount,
        'total': groupTotal,
        'percentage': groupTotal == 0 ? 0.0 : (castCount / groupTotal),
      };
    }).toList();

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
                              "${stats.totalVotesCast}/${stats.totalVerifiedVoters}",
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
              _buildBarsOnly(turnoutList),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildPieAndLegend(stats.totalVotesCast, stats.totalVerifiedVoters),

        const SizedBox(height: 60),
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
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEndedView(TurnoutStats stats) {
  final Timestamp? startTimestamp = widget.electionData['start'] as Timestamp?;

  if (startTimestamp != null) {
    final DateTime date = startTimestamp.toDate();
    const List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
  }

  final int totalVotes = stats.totalVotesCast;
  final int totalVoters = stats.totalVerifiedVoters;
  
  final List<Map<String, dynamic>> turnoutList = stats.breakdown.entries.map((e) {
    final int groupTotal = stats.groupTotalVoters[e.key] ?? 1;
    return {
      'label': e.key,
      'cast': e.value,
      'total': groupTotal,
      'percentage': groupTotal == 0 ? 0.0 : (e.value / groupTotal),
    };
  }).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),

      Container(
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(20),
        ),

        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // Header (Clickable)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEndedTurnoutVisible = !_isEndedTurnoutVisible;
                });
              },
              child: Container(
                color: Colors.transparent, // Hit test for full width
                //color: Colors.transparent, // Ensures tap target fills width
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFECECEC),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: _isEndedTurnoutVisible ? 0.5 : 0.0, // 0.0 = Down, 0.5 = Up (180deg)
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down, // Base icon is 'down'
                          color: _textColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Voter Turnout",
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Geist',
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
                            text: "$totalVotes/$totalVoters",
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

            // --- ANIMATED CONTENT (BARS) ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isEndedTurnoutVisible
                  ? Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          _buildBarsOnly(turnoutList),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity), // Collapsed state (Zero height)
            ),
          ],
        ),
      ),
      // 2. ANIMATED PIE CHART SECTION (Outside the gray box)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isEndedTurnoutVisible
              ? Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildPieAndLegend(totalVotes, totalVoters),
                  ],
                )
              : const SizedBox(width: double.infinity), // Collapsed state
        ),

        const SizedBox(height: 24),

      FutureBuilder<List<Map<String, dynamic>>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text("Error loading results: ${snapshot.error}");
          }

          final resultsData = snapshot.data ?? [];

          if (resultsData.isEmpty) {
            return const Center(child: Text("No results available."));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resultsData.length,
            itemBuilder: (context, index) {
              final positionData = resultsData[index];
              return _buildPositionResultSection(
                positionData['position'], // Title
                positionData['candidates'], // List of candidates
                showHeader: index == 0,
              );
            },
          );
        },
      ),

      ],

      


    );
  }

            // Expanded Content: Bars
            /*if (_isEndedTurnoutVisible)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    // We pass the prepared list here
                    _buildBarsOnly(turnoutList), 
                  ],
                ),
              ),
          ],
        ),
      ),

      if (_isEndedTurnoutVisible) ...[
        const SizedBox(height: 12),
        _buildPieAndLegend(totalVotes, totalVoters),
      ],

      
    ],
  );
}*/

  Widget _buildBarsOnly(List<Map<String, dynamic>> turnouts) {
    final int totalItems = turnouts.length;
    final int itemsToShow = _isExpanded
        ? totalItems
        : (totalItems > 4 ? 4 : totalItems);
    final bool showSeeMore = totalItems > 4;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            
            key: ValueKey('bars_column_$_isExpanded'), 
            children: [
              ...turnouts
                  .take(itemsToShow)
                  .map(
                    (turnoutItem) => Padding(
                      padding: const EdgeInsets.only(bottom: 0.0),
                      child: _buildTurnoutProgressBar(turnoutItem),
                    ),
                  ),
            ],
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
              child:Container(
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

  Widget _buildPieAndLegend(int cast, int total) {
    double percentage = total == 0 ? 0 : cast / total;

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
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0), // Spin from 0 to 1 full turn
                duration: const Duration(milliseconds: 1500), // 1.5 seconds
                curve: Curves.easeOutExpo, // Starts fast, slows down smoothly
                builder: (context, value, child) {
                  // 2. APPLY ROTATION
                  return Transform.rotate(
                    angle: value * 2 * 3.14159, // Convert progress (0-1) to Radians (0-360)
                    child: child,
                  );
                },
                child: RotatedBox(
                  quarterTurns: 2,
                  child: CircularPercentIndicator(
                    radius: 68.0,
                    lineWidth: 136.0,
                    percent: percentage.clamp(0.0, 1.0),
                    backgroundColor: _redAccent,
                    progressColor: _blueHighlight,
                    circularStrokeCap: CircularStrokeCap.butt,
                    animation: true,
                  ),
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
              _buildSummaryCardGroup(percentage),
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
                      "${(percentage * 100).toStringAsFixed(0)}%",
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

  Widget _buildSummaryCardGroup(double percentage) {
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
                  "${(percentage * 100).toStringAsFixed(0)}%",
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
                  "${((1.0 - percentage) * 100).toStringAsFixed(0)}%",
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

  Widget _buildPositionResultSection(
    String title,
    List<dynamic> candidates, {
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
                title,
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
                  style: TextStyle(
                    color: _subTextColor,
                    fontSize: 12,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ...candidates.map((candidate) => _buildCandidateResultCard(candidate)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCandidateResultCard(dynamic candidate) {
    final String name = candidate['name'] ?? 'Unknown';
    final int votes = (candidate['votes'] as num?)?.toInt() ?? 0;
    final bool isWinner = candidate['isWinner'] ?? false;

    final Color cardColor = isWinner ? _yellowHighlight : _bgColor;
    final BoxBorder border = isWinner
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
                name,
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
              votes.toString(),
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

  Widget _buildTurnoutProgressBar(Map<String, dynamic> data) {
    final String label = data['label'];
    final int cast = data['cast'];
    final int total = data['total'];
    final double percentage = data['percentage'];

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

          // 1. Measure the Label ("1styear")
          final TextPainter labelPainter = TextPainter(
            text: TextSpan(text: label, style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();

          // 2. Measure the Fraction ("10/100")
          final TextPainter fractionPainter = TextPainter(
            text: TextSpan(text: "$cast/$total", style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();

          // 3. Measure the Percentage ("10%")
          final TextPainter percentPainter = TextPainter(
            text: TextSpan(
              text: "${(percentage * 100).toStringAsFixed(0)}%",
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          /*final TextPainter percentPainter = TextPainter(
            text: TextSpan(
              text: "${(percentage * 100).toStringAsFixed(0)}%",
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final TextPainter fractionPainter = TextPainter(
            text: TextSpan(text: "$cast/$total", style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();

          final double percentTextWidth = percentPainter.width;
          final double fractionTextWidth = fractionPainter.width;
          const double gap = 16.0;*/

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percentage),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, animatedPercentage, child) {

              /*final double currentBarEnd = totalWidth * animatedPercentage;
              final double maxAllowedRight =
                  totalWidth - percentTextWidth - gap;

              final double actualRightEdge = (currentBarEnd < maxAllowedRight)
                  ? currentBarEnd
                  : maxAllowedRight;

              final double finalLeftPosition =
                  (actualRightEdge - fractionTextWidth) > 0
                  ? (actualRightEdge - fractionTextWidth)
                  : 0;*/
              // A. Current Bar Width
              final double currentBarEnd = totalWidth * animatedPercentage;

              // B. Calculate "Safe Left" (Label Width + Padding + Gap)
              // 16.0 is the left padding defined in the label widget below
              final double safeLeft = 16.0 + labelPainter.width + 12.0;

              // C. Calculate "Ideal Position" (Right aligned inside the bar)
              // We want the text to end 8px before the bar tip
              double calculatedLeft = currentBarEnd - fractionPainter.width - 8.0;

              // D. Apply Logic: 
              // If bar is too short, stay at safeLeft. 
              // If bar is long enough, follow the bar tip.
              if (calculatedLeft < safeLeft) {
                calculatedLeft = safeLeft;
              }

              // E. Prevent overlap with Right-side Percentage
              // 12.0 is the right padding defined in the percentage widget below
              final double maxRightStart = totalWidth - percentPainter.width - 12.0 - fractionPainter.width - 8.0;
              
              if (calculatedLeft > maxRightStart) {
                calculatedLeft = maxRightStart;
              }

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
                        child: Text(label, style: textStyle),
                      ),
                    ),
                    Positioned(
                      //left: finalLeftPosition - 10,
                      left: calculatedLeft,
                      child: SizedBox(
                        height: 34,
                        child: Center(
                          child: Text("$cast/$total", style: textStyle),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(percentage * 100).toStringAsFixed(0)}%",
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
}
