import 'package:flutter/material.dart';

class ElectionSelectionPage extends StatefulWidget {
  final String uid;
  final List<Map<String, dynamic>> activeElections;
  final Function(Map<String, dynamic>) onElectionSelected;

  const ElectionSelectionPage({
    super.key, 
    required this.uid, 
    required this.activeElections,
    required this.onElectionSelected,
  });

  @override
  State<ElectionSelectionPage> createState() => _ElectionSelectionPageState();
}

class _ElectionSelectionPageState extends State<ElectionSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20), 
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Election',
                      style: TextStyle(
                        color: Color(0xFF404040),
                        fontSize: 20, 
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${widget.activeElections.length} active elections.\nPlease select one to continue.',
                      style: const TextStyle(
                        color: Color(0xFF747474),
                        fontSize: 14,
                        fontFamily: 'Geist',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Active Election',
                style: TextStyle(
                  color: Color(0xFF404040),
                  fontSize: 14,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              //list election
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: widget.activeElections.length,
                  
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE5E5E5),
                      indent: 20,
                      endIndent: 20,
                    ),
                    
                    // List 
                    itemBuilder: (context, index) {
                      final election = widget.activeElections[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            widget.onElectionSelected(election);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    election['title'] ?? 'Election',
                                    style: const TextStyle(
                                      color: Color(0xFF404040),
                                      fontSize: 16,
                                      fontFamily: 'Geist',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}