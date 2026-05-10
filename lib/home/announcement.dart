import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:heronsvote/services/firebase_service.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'header.dart';

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

  DateTime? _parseAnnouncementDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      return parsed;
    }
    return null;
  }

  Future<List<Announcement>> getAnnouncements(String userId) async {
    final querySnapshot = await _firebaseService.getAnnouncements();

    final readIds = await _firebaseService.getReadAnnouncementIds(userId);
    final now = DateTime.now();

    // Visible to voters only when scheduledDate is now/past and status is Published.
    final visibleDocs = querySnapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] != 'Published') return false;
          final scheduled = _parseAnnouncementDate(data['scheduledDate']);
          if (scheduled == null) return false;
          return !scheduled.isAfter(now);
        })
        .toList();

    visibleDocs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aDate = _parseAnnouncementDate(aData['scheduledDate']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _parseAnnouncementDate(bData['scheduledDate']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    final announcements = visibleDocs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dateTime =
              _parseAnnouncementDate(data['scheduledDate']) ?? DateTime.now();

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
        })
        .toList();

    return announcements;
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
  bool _isOffline = false;
  final List<Announcement> _skeletonAnnouncements = [
    Announcement(
      id: 's1',
      title: 'Loading Announcement Title',
      dateDay: '00',
      dateMonth: 'Jan',
      description:
          'This is a placeholder description for the skeleton loading effect. It should be long enough to show multiple lines.',
      isNew: true,
    ),
    Announcement(
      id: 's2',
      title: 'Another Loading Title',
      dateDay: '00',
      dateMonth: 'Jan',
      description:
          'This is another placeholder description for the skeleton loading effect.',
      isNew: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (mounted) {
        setState(() {
          _isOffline = result.contains(ConnectivityResult.none);
        });
        
        if (!_isOffline && _announcements.isEmpty) {
          _loadAnnouncements();
        }
      }
    });

    _checkInternetAndLoad();
  }

  Future<void> _checkInternetAndLoad() async {
    if (mounted) setState(() => _loading = true);

    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isOffline = false;
        });
      }
      await _loadAnnouncements();
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final data = await provider.getAnnouncements(widget.userId);
      if (mounted) {
        setState(() {
          _announcements = data;
          _loading = false;
          _isOffline = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult.contains(ConnectivityResult.none)) {
           setState(() {
             _isOffline = true;
             _loading = false;
           });
        } else {
          setState(() => _loading = false);
        }
      }
    }
  }

  /*void moveToRead(String announcementId) {
    setState(() {
      _announcements = _announcements.map((a) {
        if (a.id == announcementId) return a.copyWith(isNew: false);
        return a;
      }).toList();
    });
  }*/

  //replaced version:
  Future<void> moveToRead(String announcementId) async {
    provider.markAsRead(
      userId: widget.userId, 
      announcementId: announcementId
    );
    setState(() {
      _announcements = _announcements.map((a) {
        if (a.id == announcementId) return a.copyWith(isNew: false);
        return a;
      }).toList();
    });
  }

  Widget _wrapWithPullToRefresh(Widget child) {
    return RefreshIndicator(
      onRefresh: _checkInternetAndLoad,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementsToDisplay = _loading ? _skeletonAnnouncements : _announcements;

    final newAnnouncements = announcementsToDisplay.where((a) => a.isNew).toList();
    final readAnnouncements = announcementsToDisplay.where((a) => !a.isNew).toList();

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
            CustomHeader(
              title: 'Announcements',
              onBack: () => Navigator.pop(context),
            ),

            Expanded(
              child: Builder(builder: (context) {
                
                if (!_loading && _isOffline) {
                   return _wrapWithPullToRefresh(_buildOfflineWidget());
                }

                if (!_loading && _announcements.isEmpty) {
                   return _wrapWithPullToRefresh(
                     const Text('No announcements available.'),
                   );
                }
            
                // Body
                return RefreshIndicator(
                  onRefresh: _checkInternetAndLoad,
                  child: Skeletonizer(
                    enabled: _loading,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                );
              },
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 50,
              color: Color(0xFF747474),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "You're offline",
            style: TextStyle(
              color: Color(0xFF404040),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Please check your internet connection\nto view announcements.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF747474),
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              _checkInternetAndLoad();
            },
            child: const Text(
              "Try Again",
              style: TextStyle(
                color: Color(0xFF5C6AA0),
                fontSize: 16,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
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
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },

          child: Padding(
            padding: const EdgeInsets.only(bottom: 0.0),//gap ni new and card

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
                const SizedBox(width: 9), //gap ni new text sa dot
                Text(
                  '${widget.title} (${widget.totalCount})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF404040),
                  ),
                ),
                const SizedBox(width: 9),//gap ni line sa new text
                Expanded(
                  child: Container(
                    height: 2, //line height
                    color: const Color(0xFFEEEEEE),
                    margin: const EdgeInsets.only(right: 14), // gap ni  line sa expand btn
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6), //expand icon padding relative to container
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Skeleton.ignore(
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF747474),
                      size: 20,//expand icon size
                    ),
                  ),
                ),
              ],
            ),
            
          ),
        ),

        //if (_isExpanded)
          ...widget.dateGroups.asMap().entries.map((entry) {
            final index = entry.key;
            final dateGroup = entry.value;
            final isLast = index == widget.dateGroups.length - 1;

            final keyString = '${dateGroup.dateMonth}-${dateGroup.dateDay}';

            return _DateGroupWidget(
              key: ValueKey(keyString),
              dateGroup: dateGroup,
              isLast: isLast,
              //initiallyExpanded: true,
              userId: widget.userId,

              showOnlyFirstAnnouncement: !_isExpanded,
              onMarkAsRead: widget.onMarkAsRead!, //bagong lagay
              
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
  final bool showOnlyFirstAnnouncement; //pra sa stack daw to
  final String userId;

  final void Function(String) onMarkAsRead;//bagong dagdag

  const _DateGroupWidget({
    Key? key,
    required this.dateGroup,
    required this.isLast,
    this.initiallyExpanded = true,
    //this.showOnlyFirstAnnouncement = false,
    required this.showOnlyFirstAnnouncement,
    required this.userId,
    required this.onMarkAsRead,
  }) : super(key: key);

  @override
  State<_DateGroupWidget> createState() => _DateGroupWidgetState();
}

class _DateGroupWidgetState extends State<_DateGroupWidget> {
  //late bool _isExpanded;
  //final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  //final Map<int, double> _measuredHeights = {};
  late List<Announcement> _visibleAnnouncements;

  final Map<String, double> _cardHeights = {};

  final Set<String> _exitingItemIds = {}; //remove animation ito

  @override
  void initState() {
    super.initState();
    //_isExpanded = widget.initiallyExpanded;
    /*_visibleAnnouncements = widget.showOnlyFirstAnnouncement
        ? [widget.dateGroup.announcements.first]
        : List.from(widget.dateGroup.announcements);*/
    _visibleAnnouncements = List.from(widget.dateGroup.announcements);
  }

  @override
  void didUpdateWidget(_DateGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateGroup.announcements.length != oldWidget.dateGroup.announcements.length) {
       if (mounted) {
         setState(() {
          List<Announcement> newSyncedList = List.from(widget.dateGroup.announcements);
          for (String exitingId in _exitingItemIds) {
            bool isPresentInNewList = newSyncedList.any((a) => a.id == exitingId);
            if (!isPresentInNewList) {
              try {
                final ghostItem = _visibleAnnouncements.firstWhere((a) => a.id == exitingId);
                newSyncedList.add(ghostItem);
              } catch (e) {}
            }
          }
          _visibleAnnouncements = newSyncedList;
         });
       }
    }
  }

  void _handleLocalRemoval(String id) {
    //widget.onMarkAsRead(id);
    setState(() {
      //_visibleAnnouncements.removeWhere((item) => item.id == id);
      _exitingItemIds.add(id);
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        widget.onMarkAsRead(id);
        setState(() {
          _exitingItemIds.remove(id); 
          _visibleAnnouncements.removeWhere((item) => item.id == id);
        });
      }
    });
  }

  /*void removeAnnouncement(int index) {
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
  }*/

  @override
  Widget build(BuildContext context) {

    //added from here
    final announcements = _visibleAnnouncements;
    // isCollapsed means "Stack Mode"
    final bool isCollapsed = widget.showOnlyFirstAnnouncement;

    if (announcements.isEmpty) return const SizedBox();
    if (announcements.isEmpty && _exitingItemIds.isEmpty) return const SizedBox();

    // --- Height Calculation ---
    double topCardHeight = 0;
    if (announcements.isNotEmpty) {
      // Default to 100 if we haven't measured it yet
      topCardHeight = _cardHeights[announcements.first.id] ?? 100.0;
    }

    double totalContainerHeight = 0;

    if (isCollapsed) {
      // STACK HEIGHT: Top Card + small visible lips of cards behind
      totalContainerHeight = topCardHeight;
      if (announcements.length > 1) {
        // Show max 2 cards behind the main one
        int visibleLips = (announcements.length - 1).clamp(0, 2);
        totalContainerHeight += (visibleLips * 10.0); 
      }
    } else {
      // LIST HEIGHT: Sum of all cards + spacing
      for (var a in announcements) {
        totalContainerHeight += (_cardHeights[a.id] ?? 100.0);
      }
      if (announcements.isNotEmpty) {
        totalContainerHeight += (announcements.length - 1) * 16.0; 
      }
    }//to here

    final timelineHeight = totalContainerHeight;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //date line i2 daw
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _TimelineIndicator(
              month: widget.dateGroup.dateMonth,
              day: widget.dateGroup.dateDay,
              color: widget.dateGroup.timelineColor,
              showVerticalLine: true,
              //totalCardsHeight: totalCardsHeight,
              totalCardsHeight: timelineHeight,
            ),
          ),
          const SizedBox(width: 12),

          //card stack i2
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack, // animation of stack
              height: totalContainerHeight + 8,

              child: Stack(
                clipBehavior: Clip.none,
                // Reversed so the FIRST item in the list renders LAST (on top visually)
                children: List.generate(announcements.length, (index) {
                  final item = announcements[index];
                  final isExiting = _exitingItemIds.contains(item.id);

                  // 1. Calculate List Position (Expanded)
                  double expandedTop = 0;
                  for (int i = 0; i < index; i++) {
                    expandedTop += (_cardHeights[announcements[i].id] ?? 0) + 16.0; 
                  }

                  // 2. Calculate Stack Position (Collapsed)
                  // Limit the stack effect to the first 3 items visually
                  int effectiveStackIndex = (index > 2) ? 2 : index;
                  double collapsedTop = effectiveStackIndex * 5.0; //stach peek size

                  // 3. Force Height for background cards in Stack Mode
                  // so they hide neatly behind the top card
                  bool forceHeight = isCollapsed && index > 0;

                  return AnimatedPositioned(
                    key: ValueKey(item.id), // Crucial for animation
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.fastOutSlowIn,

                    //remove animation
                    left: isExiting ? MediaQuery.of(context).size.width : 0,
                    right: isExiting ? -MediaQuery.of(context).size.width : 0,
                    
                    // The Trigger Logic:
                    top: isCollapsed ? collapsedTop : expandedTop,

                    child: AnimatedOpacity(
                      // If exiting: Fade to 0
                      opacity: isExiting ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                    

                    //left: 0,
                    //right: 0,
                      child: MeasureSize(
                        onChange: (size) {
                          bool shouldMeasure = !isCollapsed || (isCollapsed && index == 0);
                          if (shouldMeasure && _cardHeights[item.id] != size.height) {
                            setState(() {
                              _cardHeights[item.id] = size.height;
                            });
                          }                          
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          // If stacking, force background cards to match top card height
                          height: forceHeight ? topCardHeight : null,
                          child: _buildCard(
                            item, 
                            index, 
                            isCollapsed, 
                            announcements.length
                          ),
                        ),
                      ),
                    )
                  );
                }).reversed.toList(), 
              ),
            ), 
          ),

            /*child: AnimatedList(
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
            ),*/
          
        ],
      ),
    );
  }

  Widget _buildCard(Announcement item, int index, bool isCollapsed, int totalLength) {
    return _AnnouncementCard(
      key: ValueKey(item.id),
      announcement: item,
      isVisible: true,
      userId: widget.userId,
      // Logic to show "+2" badge only on the top card when stacked
      hiddenCount: (index == 0 && isCollapsed) ? totalLength - 1 : 0,
      isGroupCollapsed: isCollapsed,
      onMarkAsRead: () {
        _handleLocalRemoval(item.id);
      },
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
            child: Skeleton.ignore(
              child: Text(
                day,
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
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
  //final bool showDropdown;
  //final bool isExpanded;
  //final VoidCallback onToggle;

  final bool isGroupCollapsed; //added
  final int hiddenCount;

  const _AnnouncementCard({
    Key? key,
    required this.announcement,
    required this.isVisible,
    required this.onMarkAsRead,
    required this.userId,
    //required this.showDropdown,
    //required this.isExpanded,
    //required this.onToggle,

    this.hiddenCount = 0,
    this.isGroupCollapsed = false,

  }) : super(key: key);

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

/*class _AnnouncementCardState extends State<_AnnouncementCard>
    with TickerProviderStateMixin {
  bool _isCardExpanded = false;
  final GlobalKey _heightKey = GlobalKey();

  void _toggleExpansion() {
    setState(() => _isCardExpanded = !_isCardExpanded);
  }*/

  //replaced from here
  class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _isContentExpanded = false;

  @override
  void didUpdateWidget(_AnnouncementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset "See More" if group collapses
    if (widget.isGroupCollapsed && !oldWidget.isGroupCollapsed) {
      if (_isContentExpanded) {
        setState(() {
          _isContentExpanded = false;
        });
      }
    }
  }//to here

  @override
  Widget build(BuildContext context) {

    final isStack = widget.hiddenCount > 0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7E8E9), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8, left: 14, right: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.announcement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  if (isStack)
                    Container(
                      width: 46,
                      height: 32,
                      decoration: BoxDecoration(
                          color: const Color(0xFFECECEC),
                          borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "+${widget.hiddenCount}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.layers, size: 14, color: Color(0xFF2D2D2D)),
                        ],
                      ),
                    )
                  else
                    Opacity(
                      opacity: widget.announcement.isNew ? 1.0 : 0.0,
                      child: GestureDetector(
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
                          child: Skeleton.ignore(
                            child: const Icon(
                              Icons.check,
                              size: 24,
                              color: Color(0xFF404040),
                            ),
                          ),
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 6),

              // card Description  
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: Text(
                  key: ValueKey(_isContentExpanded),
                  widget.announcement.description,
                  maxLines: _isContentExpanded ? null : 3,
                  overflow: _isContentExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.4),
                ),
              ),
              
              /*AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _isContentExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  widget.announcement.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  widget.announcement.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                ),
              ),*/
              
              const SizedBox(height: 12),
              
              // See More
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => _isContentExpanded = !_isContentExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Skeleton.ignore(
                      child: Text(
                        _isContentExpanded ? "See less" : "See more",
                        style: const TextStyle(
                          color: Color(0xFF404040),
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
    );


    /*return AnimatedSize(
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
    );*/
  }
}

TextStyle get _descriptionStyle =>
    TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4);
