class VotingCandidate {
  final String? id;
  final String name;
  final String role;
  final String partylist;
  final String college;
  final String year;
  final String? img;

  final bool isAbstain;
  final bool isProposalOption;

  VotingCandidate({
    this.id,
    required this.name,
    required this.role,
    this.partylist = '',
    this.college = '',
    this.year = '',
    this.img,
    this.isAbstain = false,
    this.isProposalOption = false,
  });

  static VotingCandidate abstain() {
    return VotingCandidate(
      name: 'Abstain', 
      role: 'Abstain', 
      isAbstain: true,
    );
  }

  factory VotingCandidate.fromMap(Map<String, dynamic> data, String id) {
    return VotingCandidate(
      id: id,
      name: data['name'] ?? 'Unknown',
      role: data['position'] ?? 'Unknown',
      partylist: data['slate'] ?? '',
      college: data['college_id'] ?? '',
      year: data['year'] ?? '',
      img: data['img'],
    );
  }
}