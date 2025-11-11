import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'header.dart';
import 'slates_details.dart';

class SlateListPage extends StatelessWidget {
  final String electionId;

  const SlateListPage({Key? key, required this.electionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main scroll
          ListView.builder(
            padding: EdgeInsets.only(
              top: topPadding + 102, 
              left: 25,
              right: 25,
              bottom: 22,
            ),
            itemCount: placeholderSlates.length,
            itemBuilder: (context, index) {
              final slate = placeholderSlates[index];
              return SlateListItem(
                slate: slate,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SlateDetailsPage(slate: slate),
                    ),
                  );
                },
              );
            },
          ),

          // Header 
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  height: topPadding,
                  color: Colors.white,
                ),

                // Header 
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
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: CustomHeader(
                    title: 'Slates',
                    onBack: () => Navigator.pop(context),
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


class SlateListItem extends StatelessWidget {
  final Slate slate;
  final VoidCallback onTap;

  const SlateListItem({
    Key? key,
    required this.slate,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom:12 ),
        child: Container(
          height: 105, 
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFFF7F7F7),
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
              // Left placeholder image area
              Container(
                width: 131,
                height: 93,
                decoration: BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              const SizedBox(width: 15),
              // Slate Name
              Expanded(
                child: Text(
                  slate.name,
                  style: const TextStyle(
                    color: Color(0xFF404040),
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Right arrow button
              Container(
                width: 40,
                height: 93,
                decoration: const BoxDecoration(
                  color: Color(0xFF5C6AA0), // Button background color
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