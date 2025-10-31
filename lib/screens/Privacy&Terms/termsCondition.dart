import 'package:flutter/material.dart';

class TermsCondition extends StatelessWidget {
  const TermsCondition({super.key});

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

                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/BackButton.png',
                        fit: BoxFit.contain,
                      )
                    ),
                  ),

                  const SizedBox(width: 20),
                  const Text(
                    'Terms & Condition',
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
                  'Terms and Condition here.',
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