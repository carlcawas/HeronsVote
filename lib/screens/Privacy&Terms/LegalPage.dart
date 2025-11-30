import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For loading assets
import 'package:flutter_markdown/flutter_markdown.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Markdown(
              data: snapshot.data.toString(),
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                p: const TextStyle(fontSize: 16),
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading document"));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}