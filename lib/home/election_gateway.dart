// election_gateway.dart

import 'package:flutter/material.dart';
import 'package:heronsvote/home/elect_select.dart';

typedef ElectionContentBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> electionData,
  VoidCallback? onBack,
  Future<void> Function()? onRefresh,
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

  Future<void> _refreshElections() async {
    setState(() {
      _selectedElection = null;
      _electionsFuture = widget.fetchElections(widget.uid);
    });
    await _electionsFuture;
  }

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
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF354372)),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final elections = snapshot.data ?? [];

        if (elections.isEmpty) {
          // In results mode, still show the selection screen so users can open
          // archived election history even when there are no active/recent items.
          if (widget.isResultMode) {
            return ElectionSelectionPage(
              uid: widget.uid,
              activeElections: elections,
              isResultMode: widget.isResultMode,
              onRefresh: _refreshElections,
              onElectionSelected: (selected) {
                setState(() {
                  _selectedElection = selected;
                });
              },
            );
          }
          return Center(child: Text(widget.emptyMessage));
        }

        if (widget.isResultMode && elections.length > 1 && _selectedElection == null) {
          // Results mode: show list first when multiple elections exist.
          return ElectionSelectionPage(
            uid: widget.uid,
            activeElections: elections,
            isResultMode: widget.isResultMode,
            onRefresh: _refreshElections,
            onElectionSelected: (selected) {
              setState(() {
                _selectedElection = selected;
              });
            },
          );
        }

        if (!widget.isResultMode && elections.length > 1 && _selectedElection == null) {
          // Voting mode: keep in-tab selection flow.
          return ElectionSelectionPage(
            uid: widget.uid,
            activeElections: elections,
            isResultMode: widget.isResultMode,
            onRefresh: _refreshElections,
            onElectionSelected: (selected) {
              setState(() {
                _selectedElection = selected;
              });
            },
          );
        }

        // Single election or Selected -> Show Target Page
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
          widget.isResultMode ? null : _refreshElections,
        );
      },
    );
  }
}
