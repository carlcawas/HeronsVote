// election_gateway.dart

import 'package:flutter/material.dart';
import 'package:heronsvote/home/elect_select.dart';

typedef ElectionContentBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> electionData,
  VoidCallback? onBack,
);

class ElectionGateway extends StatefulWidget {
  final String uid;
  final Future<List<Map<String, dynamic>>> Function(String) fetchElections;
  final ElectionContentBuilder contentBuilder;
  final String emptyMessage;
  
  // 1. ADD THIS FLAG
  final bool isResultMode; 

  const ElectionGateway({
    super.key,
    required this.uid,
    required this.fetchElections,
    required this.contentBuilder,
    this.emptyMessage = "No elections available.",
    this.isResultMode = false, // Default is Voting Mode
  });

  @override
  State<ElectionGateway> createState() => _ElectionGatewayState();
}

class _ElectionGatewayState extends State<ElectionGateway> {
  Future<List<Map<String, dynamic>>>? _electionsFuture;
  Map<String, dynamic>? _selectedElection;

  @override
  void initState() {
    super.initState();
    _electionsFuture = widget.fetchElections(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _electionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF354372)));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final elections = snapshot.data ?? [];

        if (elections.isEmpty) {
          // NOTE: If in Result Mode, you might want to show "No results yet" instead
          return Center(child: Text(widget.emptyMessage));
        }

        // Multiple elections -> Show Selection List
        if (elections.length > 1 && _selectedElection == null) {
          return ElectionSelectionPage(
            uid: widget.uid,
            activeElections: elections,
            // 2. PASS THE FLAG HERE
            isResultMode: widget.isResultMode, 
            onElectionSelected: (selected) {
              setState(() {
                _selectedElection = selected;
              });
            },
          );
        }

        // Single election or Selected -> Show Target Page
        else {
          final targetElection = _selectedElection ?? elections.first;

          return widget.contentBuilder(
            context,
            targetElection,
            elections.length > 1
                ? () {
                    setState(() {
                      _selectedElection = null;
                    });
                  }
                : null,
          );
        }
      },
    );
  }
}