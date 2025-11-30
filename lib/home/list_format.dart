import 'package:flutter/material.dart';
import 'header.dart';

class ReusableListPage extends StatefulWidget {
  final String title;
  final VoidCallback onBack;
  final List<Widget> items;
  final String emptyMessage;

  const ReusableListPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.items,
    this.emptyMessage = 'No items found',
  });

  @override
  State<ReusableListPage> createState() => _ReusableListPageState();
}

class _ReusableListPageState extends State<ReusableListPage> {
  double _scrollOffset = 0.0;
  final double scrollThreshold = 0.5;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final newOffset = notification.metrics.pixels.clamp(0.0, scrollThreshold);
      if (newOffset != _scrollOffset) {
        setState(() {
          _scrollOffset = newOffset;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: topPadding + 85,
                left: 25,
                right: 25,
                bottom: 22,
              ),
              child: Column(
                children: [
                  if (widget.items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        widget.emptyMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontFamily: 'Geist',
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    ...widget.items,
                  const SizedBox(height: 30),
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

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(1.0), 
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.0,), 
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: CustomHeader(
                    title: widget.title,
                    onBack: widget.onBack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}