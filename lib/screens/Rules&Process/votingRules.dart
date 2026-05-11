import 'package:flutter/material.dart';
import 'package:heronsvote/home/header.dart';

class VotingRules extends StatelessWidget {
  const VotingRules({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      
      body: Stack(
        children: [

          // 1. THE CONTENT (Bottom Layer)
          SingleChildScrollView(
            // Add padding to the top so the first part of the image 
            // isn't hidden behind the status bar/header text initially.
            padding: const EdgeInsets.only(top: 110), 
            child: Column(
              children: [
                Image.asset(
                  'assets/voting_rules.png',
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // 2. THE HEADER (Top Layer)
          // Positioned at the top to float over the content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomHeader(
              title: "Voting Rules",
              onBack: () => Navigator.pop(context),
            ),
          ),

        ],
      ),
    );
  }
}
