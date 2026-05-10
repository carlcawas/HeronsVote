// election_gateway.dart

import 'package:flutter/material.dart';
import 'package:heronsvote/home/elect_select.dart';
import 'package:heronsvote/services/firebase_service.dart';

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
  Stream<List<Map<String, dynamic>>>? _electionsStream;
  Map<String, dynamic>? _selectedElection;

  Future<void> _refreshElections() async {
    final selectedId = (_selectedElection?['id'] ?? '').toString();
    setState(() {
      _electionsFuture = widget.fetchElections(widget.uid);
    });
    final refreshed = await _electionsFuture ?? <Map<String, dynamic>>[];
    if (!mounted || selectedId.isEmpty) return;
    final matched = refreshed.firstWhere(
      (e) => (e['id'] ?? '').toString() == selectedId,
      orElse: () => <String, dynamic>{},
    );
    if (!mounted) return;
    setState(() {
      _selectedElection = matched.isEmpty ? null : matched;
    });
  }

  @override
  void initState() {
    super.initState();
    _electionsFuture = widget.fetchElections(widget.uid);
    _electionsStream = widget.isResultMode
        ? FirebaseService().watchRelevantElectionsForUser(widget.uid)
        : FirebaseService().watchActiveElectionsForUser(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    if (_electionsStream != null) {
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _electionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF354372)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          return _buildFromElections(snapshot.data ?? []);
        },
      );
    }

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
        return _buildFromElections(snapshot.data ?? []);
      },
    );
  }

  Widget _buildFromElections(List<Map<String, dynamic>> elections) {
    if (_selectedElection != null) {
      final selectedId = (_selectedElection!['id'] ?? '').toString();
      final stillExists = elections.any((e) => (e['id'] ?? '').toString() == selectedId);
      if (!stillExists) {
        _selectedElection = null;
      }
    }

    if (elections.isEmpty) {
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

    if (widget.isResultMode && elections.length > 1 && _selectedElection == null) {
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
  }
}
