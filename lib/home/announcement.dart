import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:heronsvote/services/firebase_service.dart';

// Announcement model
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
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const MeasureSize({Key? key, required Widget child, required this.onChange})
    : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderBox
    with RenderObjectWithChildMixin<RenderBox>, RenderProxyBoxMixin<RenderBox> {
  ValueChanged<Size> onChange;
  Size? _oldSize;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    // Detects if size changed during this layout pass
    if (size != _oldSize) {
      _oldSize = size;
      // Notify parent immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(size);
      });
    }
  }
}

// Provider
class AnnouncementProvider {
  static const String collectionName = 'announcements';
  final FirebaseService _firebaseService = FirebaseService();

  Future<List<Announcement>> getAnnouncements(String userId) async {
    final querySnapshot = await _firebaseService.getAnnouncements();

    final readIds = await _firebaseService.getReadAnnouncementIds(userId);

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

  Future<void> markAsRead({
    required String userId,
    required String announcementId,
  }) async {
    await _firebaseService.markAnnouncementAsRead(
      userId: userId,
      announcementId: announcementId,
    );
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

// App
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
            // Body
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

// Announcement Section
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
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.title} (${widget.totalCount})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF404040),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 2,
                  color: const Color(0xFFEEEEEE),
                  margin: const EdgeInsets.only(right: 8),
                ),
              ),
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

        if (_isExpanded)
          ...widget.dateGroups.asMap().entries.map((entry) {
            final index = entry.key;
            final dateGroup = entry.value;
            final isLast = index == widget.dateGroups.length - 1;

            final keyString =
                '${dateGroup.dateMonth}-${dateGroup.dateDay}-${dateGroup.announcements.length}';

            return _DateGroupWidget(
              key: ValueKey(keyString),
              dateGroup: dateGroup,
              isLast: isLast,
              initiallyExpanded: true,
              showOnlyFirstAnnouncement: false,
              userId: widget.userId,
            );
          }).toList(),
      ],
    );
  }
}

// DateGroup Widget with Animated Line
class _DateGroupWidget extends StatefulWidget {
  final DateGroup dateGroup;
  final bool isLast;
  final bool initiallyExpanded;
  final bool showOnlyFirstAnnouncement;
  final String userId;

  const _DateGroupWidget({
    Key? key,
    required this.dateGroup,
    required this.isLast,
    this.initiallyExpanded = true,
    this.showOnlyFirstAnnouncement = false,
    required this.userId,
  }) : super(key: key);

  @override
  State<_DateGroupWidget> createState() => _DateGroupWidgetState();
}

class _DateGroupWidgetState extends State<_DateGroupWidget> {
  late bool _isExpanded;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Map<int, double> _measuredHeights = {};
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
    final removedItem = _visibleAnnouncements[index];
    _visibleAnnouncements.removeAt(index);

    _listKey.currentState!.removeItem(index, (context, animation) {
      final slideTween = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      return SlideTransition(
        position: slideTween,
        child: FadeTransition(
          opacity: animation,
          child: _AnnouncementCard(
            key: ValueKey(removedItem.id),
            announcement: removedItem,
            isVisible: true,
            userId: widget.userId,
            showDropdown: false,
            isExpanded: false,
            onToggle: () {},
            onMarkAsRead: () {},
          ),
        ),
      );
    }, duration: const Duration(milliseconds: 350));

    if (mounted) setState(() {});
  }

  double get totalCardsHeight {
    final cardsTotal = _measuredHeights.values.fold(0.0, (sum, h) => sum + h);
    return cardsTotal + 3.0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: _TimelineIndicator(
              month: widget.dateGroup.dateMonth,
              day: widget.dateGroup.dateDay,
              color: widget.dateGroup.timelineColor,
              showVerticalLine: !widget.isLast,
              totalCardsHeight: totalCardsHeight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _visibleAnnouncements.length,
              itemBuilder: (context, index, animation) {
                if (index >= _visibleAnnouncements.length)
                  return const SizedBox();
                final announcement = _visibleAnnouncements[index];

                return MeasureSize(
                  onChange: (size) {
                    if (_measuredHeights[index] != size.height) {
                      _measuredHeights[index] = size.height;
                      if (mounted) setState(() {});
                    }
                  },
                  child: SizeTransition(
                    sizeFactor: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _AnnouncementCard(
                          key: ValueKey(announcement.id),
                          announcement: announcement,
                          isVisible: true,
                          userId: widget.userId,
                          showDropdown:
                              widget.dateGroup.announcements.length > 1 &&
                              !_isExpanded,
                          isExpanded: _isExpanded,
                          onToggle: () {
                            setState(() => _isExpanded = !_isExpanded);
                          },
                          onMarkAsRead: () {
                            removeAnnouncement(index);
                            AnnouncementProvider().markAsRead(
                              userId: widget.userId,
                              announcementId: announcement.id,
                            );
                            Future.delayed(
                              const Duration(milliseconds: 350),
                              () {
                                if (context.mounted) {
                                  context
                                      .findAncestorStateOfType<
                                        _AnnouncementsPageState
                                      >()!
                                      .moveToRead(announcement.id);
                                }
                              },
                            );
                          },
                        ),
                      ),
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

class _TimelineIndicator extends StatelessWidget {
  final String month;
  final String day;
  final Color color;
  final bool showVerticalLine;
  final double totalCardsHeight;

  const _TimelineIndicator({
    Key? key,
    required this.month,
    required this.day,
    required this.color,
    required this.showVerticalLine,
    required this.totalCardsHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double headerOffsetToSubtract = 64.0; //TODO: eyeballin to pra sa linya
    final double lineHeight = (totalCardsHeight - headerOffsetToSubtract).clamp(
      0.0,
      double.infinity,
    );

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
          if (showVerticalLine)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 2,
              height: lineHeight,
              color: color,
              margin: const EdgeInsets.only(top: 8),
            ),
        ],
      ),
    );
  }
}

// Announcement Card
class _AnnouncementCard extends StatefulWidget {
  final Announcement announcement;
  final bool isVisible;
  final VoidCallback onMarkAsRead;
  final String userId;
  final bool showDropdown;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AnnouncementCard({
    Key? key,
    required this.announcement,
    required this.isVisible,
    required this.onMarkAsRead,
    required this.userId,
    required this.showDropdown,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard>
    with TickerProviderStateMixin {
  bool _isCardExpanded = false;
  final GlobalKey _heightKey = GlobalKey();

  void _toggleExpansion() {
    setState(() => _isCardExpanded = !_isCardExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: widget.isVisible ? 1.0 : 0.0,
        child: AnimatedContainer(
          key: _heightKey,
          duration: const Duration(milliseconds: 1500),
          curve: Curves.elasticInOut,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
            padding: const EdgeInsets.only(
              top: 12,
              right: 15,
              left: 15,
              bottom: 12,
            ),
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: widget.announcement.isNew
                          ? widget.onMarkAsRead
                          : null,
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
                    style: _descriptionStyle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(
                    widget.announcement.description,
                    style: _descriptionStyle,
                  ),
                ),

                const SizedBox(height: 12),

                // See more / See less button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1.0,
                            child: child,
                          ),
                        );
                      },
                  child: Align(
                    key: ValueKey(_isCardExpanded),
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
                        child: Text(
                          _isCardExpanded ? "See less" : "See more",
                          style: const TextStyle(
                            color: Color(0xFF404040),
                            fontFamily: 'Geist',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle get _descriptionStyle =>
    TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4);
