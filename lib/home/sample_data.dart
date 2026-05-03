
// INALIS KO SA IMPORT SA IBANG DART FILES --- SAME CLASS NAME KASI GINAMIT KO PARA DI NAKAKALITO
// In sample_data.dart
class Candidate{
  final String? id;
  final String name;
  final String role;
  final String details;
  final String age;
  final String year;
  final String college;
  final String partylist;
  final String advocacy;
  final String platform;
  final String? img;
  
  Candidate({
    this.id,
    required this.name,
    required this.role,
    required this.details,
    required this.age,
    required this.year,
    required this.college,
    required this.partylist,
    required this.advocacy,
    required this.platform,
    this.img,
  });
}

// INALIS KO RIN SA IMPORT SA IBA
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


final List<Slate> placeholderSlates = [
  Slate(
    name: 'The Loremlpsum Partylist',
    advocacy: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
    platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
    candidates: [
      Candidate(
        name: 'Rhic Ruzel H. Reyes',
        role: 'Chairperson',
        details: 'CCIS - 3rd year',
        age: '21',
        year: '3rd',
        college: 'College of Computing and Information Sciences',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
        platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',

      ),
      Candidate(
        name: 'Jane Doe',
        role: 'Vice Chairperson',
        details: 'CCIS - 2nd year',
        age: '20',
        year: '2nd',
        college: 'CCIS',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Advocacy for student rights and digital innovation.',
        platform:  'Lorem Ipsum is simply dummy text of the printing and typesetting industry.'
      ),
      Candidate(
        name: 'John Smith',
        role: 'Secretary',
        details: 'CCIS - 3rd year',
        age: '22',
        year: '3rd',
        college: 'ION',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Promoting academic excellence and student welfare.',
        platform:  'Lorem Ipsum is simply dummy text of the printing and typesetting industry.'

      ),
      Candidate(
        name: 'Sarah Johnson',
        role: 'Treasurer',
        details: 'CCIS - 4th year',
        age: '23',
        year: '4th',
        college: 'ML',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Financial transparency and budget management for student organizations.',
        platform:  'Lorem Ipsum is simply dummy text of the printing and typesetting industry.'

      ),
    ],
  ),
  Slate(
    name: 'The Second Partylist', 
    advocacy: 'Second partylist advocacy description...',
    platform: 'Second partylist platform description...',
    candidates: [
      Candidate(
        name: 'Candidate One',
        role: 'Chairperson',
        details: 'Engineering - 2nd year',
        age: '20',
        year: '2nd',
        college: 'College of Engineering',
        partylist: 'The Second Partylist',
        advocacy: 'Engineering and innovation advocacy.',
        platform:  'Lorem Ipsum is simply dummy text of the printing and typesetting industry.'
      ),
    ],
  ),
  Slate(
    name: 'The Third Partylist', 
    advocacy: 'Third partylist advocacy description...',
    platform: 'Third partylist platform description...',
    candidates: [
       Candidate(
        name: 'Rhic Ruzel H. Reyes',
        role: 'Chairperson',
        details: 'CCIS - 3rd year',
        age: '21',
        year: '3rd',
        college: 'College of Computing and Information Sciences',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
        platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',

      ),
       Candidate(
        name: 'Rhic Ruzel H. Reyes',
        role: 'Chairperson',
        details: 'CCIS - 3rd year',
        age: '21',
        year: '3rd',
        college: 'College of Computing and Information Sciences',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
        platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',

      ),
       Candidate(
        name: 'Rhic Ruzel H. Reyes',
        role: 'Chairperson',
        details: 'CCIS - 3rd year',
        age: '21',
        year: '3rd',
        college: 'College of Computing and Information Sciences',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
        platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',

      ),
       Candidate(
        name: 'Rhic Ruzel H. Reyes',
        role: 'Chairperson',
        details: 'CCIS - 3rd year',
        age: '21',
        year: '3rd',
        college: 'College of Computing and Information Sciences',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
        platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',

      ),
       Candidate(
        name: 'Rhic Ruzel H. Reyes',
        role: 'Chairperson',
        details: 'CCIS - 3rd year',
        age: '21',
        year: '3rd',
        college: 'College of Computing and Information Sciences',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
        platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',

      ),
       Candidate(
        name: 'Rhic Ruzel H. Reyes',
        role: 'Chairperson',
        details: 'CCIS - 3rd year',
        age: '21',
        year: '3rd',
        college: 'College of Computing and Information Sciences',
        partylist: 'The Loremlpsum Partylist',
        advocacy: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
        platform: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',

      ),
      
    ],
  ),
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

/* offisyalz
final List<Official> placeholderOfficials = [
  Official(
    position: 'President',
    name: 'Rhic Ruzel H. Reyes',
    details: 'CCIS - 3rd year',
    party: 'The Slate Partylist',
    affiliation: 'USC',
  ),
  Official(
    position: 'Vice President',
    name: 'Rhic Ruzel H. Reyes',
    details: 'CCIS - 3rd year',
    party: 'The Slate Partylist',
    affiliation: 'USC',
  ),
  Official(
    position: 'Secretary',
    name: 'Rhic Ruzel H. Reyes',
    details: 'CCIS - 3rd year',
    party: 'The Slate Partylist',
    affiliation: 'USC',
  ),
  Official(
    position: 'Auditor',
    name: 'Rhic Ruzel H. Reyes',
    details: 'CCIS - 3rd year',
    party: 'The Slate Partylist',
    affiliation: 'USC',
  ),

  Official(
    position: 'Chairperson',
    name: 'Rhic Ruzel H. Reyes',
    details: 'CAS - 4th year',
    party: 'Blue Party',
    affiliation: 'CCIS',
  ),
  Official(
    position: 'Vice Chairperson',
    name: 'Rhic Ruzel H. Reyes',
    details: 'CED - 2nd year',
    party: 'Red Party',
    affiliation: 'CCIS',
  ),
];
*/

// Position model
class Position {
  final String title;
  final String path;
  Position({required this.title, required this.path});
}

// Proposal class
class Proposal {
  final String id;
  final String title;
  final String proposalName;
  final String? summary;
  final String? rationale;
  final String? comparison;
  final String? resources;
  final String? path; // Added path for navigation if needed

  Proposal({
    required this.id,
    required this.title,
    this.proposalName = 'Proposal Name',
    this.summary,
    this.rationale,
    this.comparison,
    this.resources,
    this.path,
  });
}

/* COMMENT KO SINCE REPLACED NA BY ACTUAL DATA

final List<Proposal> placeholderProposals = [
  Proposal(
    title: 'Campus WiFi Improvement',
    path: 'wifi_id',
    summary: 'Upgrade campus-wide WiFi infrastructure to provide faster and more reliable internet access for all students.',
    rationale: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
    comparison: 'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
    resources: 'Phase 1: Infrastructure assessment\nPhase 2: Equipment installation\nPhase 3: Testing and optimization',
  ),
  Proposal(
    title: 'Student Lounge Renovation',
    path: 'lounge_id',
    summary: 'Renovate the main student lounge to create a more comfortable and functional space.',
    rationale: 'The current lounge is outdated and lacks adequate seating and charging stations.',
    comparison: '• Add 50 new comfortable seats\n• Install 30 charging stations\n• Upgrade lighting and ventilation',
    resources: 'Budget: ₱500,000\nTimeline: 3 months\nContractor: Campus Facilities Team',
  ),
  Proposal(
    title: 'University CBL',
    path: 'cbl_id',
    summary: 'Update the University Constitution and By-Laws to reflect current student needs.',
    rationale: 'The current CBL was written 10 years ago and no longer addresses modern student concerns.',
  ),
  Proposal(
    title: 'Policy Amendment',
    path: 'amendment_id',
    summary: 'Amend existing student policies to be more inclusive and fair.',
    rationale: 'Several policies have been identified as outdated or discriminatory.',
    resources: 'Review committee: Student Affairs Office\nTimeline: 6 months',
  ),
];
*/

final List<Position> placeholderPositions = [
  Position(title: 'Chairperson', path: 'chairperson_id'),
  Position(title: 'Vice Chairperson', path: 'vice_chairperson_id'),
  Position(title: 'Secretary', path: 'secretary_id'),
  Position(title: 'Treasurer', path: 'treasurer_id'),
  Position(title: 'Auditor', path: 'auditor_id'),
  Position(title: '2nd Year Representative', path: 'rep2_id'),
  Position(title: '3rd Year Representative', path: 'rep3_id'),
  Position(title: '4th Year Representative', path: 'rep4_id'),
];
