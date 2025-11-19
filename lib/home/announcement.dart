import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:heronsvote/services/firebase_service.dart';

//model for announcement item.
class Announcement {
  final String id;
  final String title;
  final String dateDay;
  final String dateMonth;
  final String description;
  final bool isNew;

  Announcement({
    required this.id,
    required this.title,
    required this.dateDay,
    required this.dateMonth,
    required this.description,
    this.isNew = true,
  });

  Announcement copyWith({bool? isNew}) {
    return Announcement(
      id: id,
      title: title,
      dateDay: dateDay,
      dateMonth: dateMonth,
      description: description,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  String toString() {
    return 'Announcement(title: $title, date: $dateMonth $dateDay, isNew: $isNew)';
  }
}

class AnnouncementProvider {
  static const String collectionName = 'announcements';

  Future<List<Announcement>> getAnnouncements(String userId) async {
    final querySnapshot = await FirebaseService().getAnnouncements();
    final readDoc = await FirebaseService().getReadAnnouncements(userId);

    final readIds = readDoc.exists
        ? List<String>.from(readDoc.get('announcement_ids') ?? [])
        : <String>[];

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['posted_at'] as Timestamp?;
      final dateTime = timestamp?.toDate() ?? DateTime.now();

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = _getMonthAbbreviate(dateTime.month);

      return Announcement(
        id: doc.id,
        title: data['title'] ?? 'No Title',
        dateDay: day,
        dateMonth: month,
        description: data['message'] ?? 'No Description',
        isNew: !readIds.contains(doc.id),
      );
    }).toList();
  }
}

String _getMonthAbbreviate(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

/*
  //debug dihhhta
  final List<Announcement> announcements = [
    Announcement(
      id: "0101010",
      title: 'Upcoming election on Nov',
      dateDay: '17',
      dateMonth: 'Oct',
      description:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
      isNew: true,
    ),
    Announcement(
      id: "010101000",
      title: 'System Maintenance Notice',
      dateDay: '17',
      dateMonth: 'Oct',
      description:
          'The system will undergo maintenance tonight from 12 AM to 4 AM. Please save all work and log out before 11:30 PM.',
      isNew: true,
    ),
    Announcement(
      id: "0101010000",
      title: 'Campus Event Update',
      dateDay: '17',
      dateMonth: 'Oct',
      description:
          'The campus event scheduled for this weekend has been moved to the main auditorium.',
      isNew: true,
    ),
    Announcement(
      id: "335142",
      title: 'Upcoming election on Nov',
      dateDay: '17',
      dateMonth: 'Oct',
      description:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
      isNew: false,
    ),
    Announcement(
      id: "01010103747347",
      title: 'Library Hours Change',
      dateDay: '16',
      dateMonth: 'Oct',
      description:
          'Library hours have been extended for finals week. New closing time is 11 PM.',
      isNew: false,
    ),
    Announcement(
      id: "01010ggng10",
      title: 'Upcoming election on Nov',
      dateDay: '16',
      dateMonth: 'Oct',
      description:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      isNew: false,
    ),
  ];
  */

class AnnouncementApp extends StatelessWidget {
  final String userId;
  const AnnouncementApp({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Geist',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      home: AnnouncementsPage(userId: userId),
    );
  }
}

// Grouped Announcement Model
class DateGroup {
  final String dateDay;
  final String dateMonth;
  final List<Announcement> announcements;
  final Color timelineColor;

  DateGroup({
    required this.dateDay,
    required this.dateMonth,
    required this.announcements,
    required this.timelineColor,
  });
}

// Main Screen
class AnnouncementsPage extends StatefulWidget {
  final String userId;
  const AnnouncementsPage({super.key, required this.userId});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final AnnouncementProvider provider = AnnouncementProvider();
  List<Announcement> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final data = await provider.getAnnouncements(widget.userId);
    setState(() {
      _announcements = data;
      _loading = false;
    });
  }

  void moveToRead(String announcementId) {
    setState(() {
      _announcements = _announcements.map((a) {
        if (a.id == announcementId) return a.copyWith(isNew: false);
        return a;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_announcements.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No announcements available.')),
      );
    }

    final newAnnouncements = _announcements.where((a) => a.isNew).toList();
    final readAnnouncements = _announcements.where((a) => !a.isNew).toList();

    final newDateGroups = _groupAnnouncementsByDate(
      newAnnouncements,
      const Color(0xFFF09062),
    );
    final readDateGroups = _groupAnnouncementsByDate(
      readAnnouncements,
      const Color(0xFF74B6F9),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                left: 25,
                bottom: 9,
                top: 25,
                right: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5C6AA0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/back.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'Announcements',
                    style: TextStyle(
                      color: Color(0xFF404040),
                      fontFamily: 'Geist',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Body content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _AnnouncementSection(
                        title: 'New',
                        color: const Color(0xFFF2A464),
                        dateGroups: newDateGroups,
                        totalCount: newAnnouncements.length,
                        userId: widget.userId,
                        onMarkAsRead: moveToRead,
                      ),
                      const SizedBox(height: 16),
                      _AnnouncementSection(
                        title: 'Read',
                        color: const Color(0xFF74B6F9),
                        dateGroups: readDateGroups,
                        totalCount: readAnnouncements.length,
                        userId: widget.userId,
                        onMarkAsRead: moveToRead,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DateGroup> _groupAnnouncementsByDate(
    List<Announcement> announcements,
    Color color,
  ) {
    final Map<String, List<Announcement>> groupedMap = {};
    for (final a in announcements) {
      final key = '${a.dateMonth}-${a.dateDay}';
      groupedMap.putIfAbsent(key, () => []).add(a);
    }
    return groupedMap.entries.map((e) {
      final parts = e.key.split('-');
      return DateGroup(
        dateMonth: parts[0],
        dateDay: parts[1],
        announcements: e.value,
        timelineColor: color,
      );
    }).toList()..sort((a, b) => b.dateDay.compareTo(a.dateDay));
  }
}

// Header section
class _AnnouncementSection extends StatefulWidget {
  final String title;
  final Color color;
  final List<DateGroup> dateGroups;
  final int totalCount;
  final String userId;
  final bool initiallyExpanded;
  final void Function(String)? onMarkAsRead;

  const _AnnouncementSection({
    required this.title,
    required this.color,
    required this.dateGroups,
    required this.totalCount,
    required this.userId,
    this.initiallyExpanded = true,
    required this.onMarkAsRead,
  });

  @override
  State<_AnnouncementSection> createState() => _AnnouncementSectionState();
}

class _AnnouncementSectionState extends State<_AnnouncementSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              // Colored dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              // Section title
              Text(
                '${widget.title} (${widget.totalCount})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF404040),
                ),
              ),
              const SizedBox(width: 8),
              // Horizontal line beside title
              Expanded(
                child: Container(
                  height: 2,
                  color: Color(0xFFEEEEEE),
                  margin: const EdgeInsets.only(right: 8),
                ),
              ),
              // Dropdown arrow
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF747474),
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // Show ALL date groups limit announcements when collapsed
        ...widget.dateGroups.asMap().entries.map((entry) {
          final index = entry.key;
          final dateGroup = entry.value;
          final isLast = index == widget.dateGroups.length - 1;

          return _DateGroupWidget(
            dateGroup: dateGroup,
            isLast: isLast,
            initiallyExpanded: _isExpanded,
            showOnlyFirstAnnouncement: !_isExpanded,
            userId: widget.userId,
          );
        }).toList(),
      ],
    );
  }
}

Future<void> markAsRead({
  required String userId,
  required String announcementId,
}) async {
  final firestore = FirebaseFirestore.instance;
  final readDocRef = firestore
      .collection('users')
      .doc(userId)
      .collection('read_status')
      .doc('read_announcements');

  unawaited(
    firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(readDocRef);

      if (!snapshot.exists) {
        transaction.set(readDocRef, {
          'announcement_ids': [announcementId],
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        final currentIds = snapshot.get('announcement_ids') ?? [];
        if (!currentIds.contains(announcementId)) {
          transaction.update(readDocRef, {
            'announcement_ids': FieldValue.arrayUnion([announcementId]),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    }),
  );
}

//check dates of announcements and collect them based on dates

class _DateGroupWidget extends StatefulWidget {
  final DateGroup dateGroup;
  final bool isLast;
  final bool initiallyExpanded;
  final bool showOnlyFirstAnnouncement;
  final String userId;

  const _DateGroupWidget({
    required this.dateGroup,
    required this.isLast,
    this.initiallyExpanded = true,
    this.showOnlyFirstAnnouncement = false,
    required this.userId,
  });

  @override
  State<_DateGroupWidget> createState() => _DateGroupWidgetState();
}

class _DateGroupWidgetState extends State<_DateGroupWidget> {
  late bool _isExpanded;
  double _totalHeight = 150.0;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Announcement> _visibleAnnouncements;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _visibleAnnouncements = widget.showOnlyFirstAnnouncement
        ? [widget.dateGroup.announcements.first]
        : List.from(widget.dateGroup.announcements);
  }

  void removeAnnouncement(int index) {
    final removed = _visibleAnnouncements.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => FadeTransition(
        opacity: animation,
        child: _AnnouncementCard(announcement: removed, userId: widget.userId),
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  void addAnnouncement(Announcement announcement) {
    _visibleAnnouncements.insert(0, announcement);
    _listKey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _updateTotalHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double newHeight = 0;
      final visibleCount = widget.showOnlyFirstAnnouncement
          ? 1
          : widget.dateGroup.announcements.length;

      for (int i = 0; i < visibleCount; i++) {
        final announcement = widget.dateGroup.announcements[i];
        final estimatedHeight = _estimateCardHeight(announcement);
        newHeight += estimatedHeight;

        if (i < visibleCount - 1) {
          newHeight += 12.0;
        }
      }

      if (mounted && newHeight != _totalHeight) {
        setState(() {
          _totalHeight = newHeight;
        });
      }
    });
  }

  double _estimateCardHeight(Announcement announcement) {
    const double baseHeight = 80.0;
    const double lineHeight = 16.8;
    const int maxLines = 3;

    final descriptionHeight = lineHeight * maxLines;

    return baseHeight + descriptionHeight;
  }

  @override
  void didUpdateWidget(covariant _DateGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showOnlyFirstAnnouncement !=
            oldWidget.showOnlyFirstAnnouncement ||
        widget.dateGroup != oldWidget.dateGroup) {
      _updateTotalHeight();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which announcements to show
    final visibleAnnouncements = widget.showOnlyFirstAnnouncement
        ? [widget.dateGroup.announcements.first]
        : widget.dateGroup.announcements;

    // Update height
    _updateTotalHeight();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator
          _TimelineIndicator(
            month: widget.dateGroup.dateMonth,
            day: widget.dateGroup.dateDay,
            color: widget.dateGroup.timelineColor,
            showVerticalLine: !widget.isLast,
            announcementCount: visibleAnnouncements.length,
            isExpanded: !widget.showOnlyFirstAnnouncement,
            totalAnnouncements: visibleAnnouncements.length,
            totalCardsHeight: _totalHeight,
          ),
          const SizedBox(width: 12),
          // Announcements for this date
          Expanded(
            child: AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _visibleAnnouncements.length,
              itemBuilder: (context, index, animation) {
                final announcement = _visibleAnnouncements[index];
                return FadeTransition(
                  opacity: animation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _AnnouncementCard(
                      announcement: announcement,
                      userId: widget.userId,
                      showDropdown:
                          widget.dateGroup.announcements.length > 1 &&
                          !_isExpanded,
                      isExpanded: _isExpanded,
                      onToggle: () {
                        setState(() => _isExpanded = !_isExpanded);
                      },
                      onMarkAsRead: () {
                        removeAnnouncement(index); // fade out
                        markAsRead(
                          userId: widget.userId,
                          announcementId: announcement.id,
                        );
                        context
                            .findAncestorStateOfType<_AnnouncementsPageState>()!
                            .moveToRead(announcement.id);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//Time line //date month line

class _TimelineIndicator extends StatelessWidget {
  final String month;
  final String day;
  final Color color;
  final bool showVerticalLine;
  final int announcementCount;
  final bool isExpanded;
  final int totalAnnouncements;
  final double totalCardsHeight;

  const _TimelineIndicator({
    required this.month,
    required this.day,
    required this.color,
    required this.showVerticalLine,
    required this.announcementCount,
    required this.isExpanded,
    required this.totalAnnouncements,
    required this.totalCardsHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          Text(
            month,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF404040),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: const TextStyle(
                color: Color(0xFFF8F8F8),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          //Vertical line
          Container(
            width: 2,
            height: _calculateLineHeight(),
            color: color,
            margin: const EdgeInsets.only(top: 8),
          ),
        ],
      ),
    );
  }

  double _calculateLineHeight() {
    const double topSpacing = 8.0;
    const double bottomAdjustment = 30.0;
    return totalCardsHeight + topSpacing - bottomAdjustment;
  }
}
//Announcement Card

class _AnnouncementCard extends StatefulWidget {
  final Announcement announcement;
  final String userId;
  final bool showDropdown;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback? onMarkAsRead;

  const _AnnouncementCard({
    required this.announcement,
    required this.userId,
    this.showDropdown = false,
    this.isExpanded = true,
    this.onToggle,
    this.onMarkAsRead,
  });

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _isCardExpanded = false;

  void _toggleExpansion() {
    setState(() {
      _isCardExpanded = !_isCardExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticInOut,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 15, left: 15, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Checkmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.announcement.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget
                      .onMarkAsRead, // call the function passed from parent
                  child: Container(
                    width: 36,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECECEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 24,
                      color: Color(0xFF404040),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isCardExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                widget.announcement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                widget.announcement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // "See more"
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  ),
                );
              },
              child: _isCardExpanded
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _toggleExpansion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            "See less",
                            style: TextStyle(
                              color: Color(0xFF404040),
                              fontFamily: 'Geist',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _toggleExpansion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            "See more",
                            style: TextStyle(
                              color: Color(0xFF404040),
                              fontFamily: 'Geist',
                              fontSize: 12,
                            ),
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
