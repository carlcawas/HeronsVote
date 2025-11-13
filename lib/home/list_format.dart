import 'package:flutter/material.dart';
import 'header.dart';

class ReusableListPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(
              title: title,
              onBack: onBack,
            ),
            if (items.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No candidates are running for this position.',
                    style: TextStyle(color: Color(0xFF8C8C8C), fontFamily: 'Geist', fontSize: 16,),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
                  itemCount: items.length,
                  itemBuilder: (context, index) => items[index],
                ),
              ),
          ],
        ),
      ),
    );
  }
}