class Candidate {
  final String role;
  final String name;
  final String details; //pede to section dn 
  final String party;

  Candidate({
    required this.role,
    required this.name,
    required this.details,
    required this.party,
  });
}

class Slate {
  final String name;
  final String advocacy;
  final String platform;
  final List<Candidate> candidates;

  Slate({
    required this.name,
    required this.advocacy,
    required this.platform,
    required this.candidates,
  });
}

// Placeholder Data
final List<Slate> placeholderSlates = [
  Slate(
    name: 'The Loremlpsum Partylist',
    advocacy: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
    platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
    candidates: [
      Candidate(role: 'Chairperson', name: 'Rhic Ruzel H. Reyes', details: 'CCIS - 3rd year', party: 'The Slate Partylist'),
      Candidate(role: 'Vice Chairperson', name: 'Rhic Ruzel H. Reyes', details: 'CCIS - 3rd year', party: 'The Slate Partylist'),
      Candidate(role: 'Secretary', name: 'Rhic Ruzel H. Reyes', details: 'CCIS - 3rd year', party: 'The Slate Partylist'),
      Candidate(role: 'Treasurer', name: 'Rhic Ruzel H. Reyes', details: 'CCIS - 3rd year', party: 'The Slate Partylist'),
    ],
  ),
  Slate(name: 'The Second Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Third Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Fourth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Fifth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),
  Slate(name: 'The Sixth Partylist', advocacy: '...', platform: '...', candidates: []),

];


class Official {
  final String position;
  final String name;
  final String details; 
  final String party;
  final String affiliation; // 'USC' or 'Department'

  Official({
    required this.position,
    required this.name,
    required this.details,
    required this.party,
    required this.affiliation,
  });
}
//offisyalz
final List<Official> placeholderOfficials = [
  Official(position: 'President', name: 'Rhic Ruzel H. Reyes', details: 'CCIS - 3rd year', party: 'The Slate Partylist', affiliation: 'USC'),
  Official(position: 'Vice President', name: 'Rhic Ruzel H. Reyes', details: 'CCIS - 3rd year', party: 'The Slate Partylist', affiliation: 'USC'),
  Official(position: 'Secretary', name: 'Rhic Ruzel H. Reyes', details: 'CCIS - 3rd year', party: 'The Slate Partylist', affiliation: 'USC'),
  Official(position: 'Auditor', name: 'Rhic Ruzel H. Reyes', details: 'CCIS - 3rd year', party: 'The Slate Partylist', affiliation: 'USC'),

  Official(position: 'Chairperson', name: 'Rhic Ruzel H. Reyes', details: 'CAS - 4th year', party: 'Blue Party', affiliation: 'CCIS'),
  Official(position: 'Vice Chairperson', name: 'Rhic Ruzel H. Reyes', details: 'CED - 2nd year', party: 'Red Party', affiliation: 'CCIS'),
];