import 'sample_data.dart';

class VotedCandidate {
  final String name;
  final String details;
  final String partylist;

  const VotedCandidate({
    required this.name,
    required this.details,
    required this.partylist,
  });
}

class CandidateWithParty {
  final Candidate candidate;
  final String partylistName;

  const CandidateWithParty({
    required this.candidate,
    required this.partylistName,
  });
}