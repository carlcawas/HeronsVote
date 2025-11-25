class TurnoutStats {
  final Map<String, int> breakdown;
  final Map<String, int> groupTotalVoters;
  final int totalVotesCast;
  final int totalVerifiedVoters;

  TurnoutStats({
    required this.breakdown,
    required this.groupTotalVoters,
    required this.totalVotesCast,
    required this.totalVerifiedVoters,
  });
}