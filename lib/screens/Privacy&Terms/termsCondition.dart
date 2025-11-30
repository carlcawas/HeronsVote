import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; 
import 'package:flutter_svg/flutter_svg.dart';

class TermsCondition extends StatelessWidget {
  final String mdFileName;

  const TermsCondition({super.key, this.mdFileName = 'terms_conditions.md'});

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
                    'Terms & Conditions',
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
            Expanded(
              child: FutureBuilder(
                // 3. Load from the specific 'assets/legal/' folder
                future: rootBundle.loadString('assets/legal/$mdFileName'),
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.hasData) {
                    return Markdown(
                      data: snapshot.data!,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: Color(0xFF404040),
                          fontFamily: 'Geist',
                          fontSize: 16,
                        ),
                        h1: const TextStyle(
                          color: Color(0xFF404040),
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        h2: const TextStyle(
                          color: Color(0xFF404040),
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        h3: const TextStyle(
                          color: Color(0xFF404040),
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        listBullet: const TextStyle(color: Color(0xFF404040)),
                        blockSpacing: 15.0,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading Terms & Conditions.\nEnsure 'assets/legal/$mdFileName' exists.",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF5C6AA0),
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
}