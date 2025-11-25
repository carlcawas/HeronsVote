import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VotingRules extends StatelessWidget {
  const VotingRules({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2D7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 25, bottom: 9, top: 25, right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },

                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5C6AA0),
                      ),
                      child: SvgPicture.asset(
                        'assets/back.svg',
                        fit: BoxFit.contain,
                      )
                    ),
                  ),

                  const SizedBox(width: 20),
                  const Text(
                    'Voting Rules',
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
            const Divider(color: Colors.white24),

            // Body
            const Expanded(
              child: Center(
                child: Text(
                  'Voting Rules here.',
                  style: TextStyle(color: Color.fromARGB(255, 64, 64, 64), fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}