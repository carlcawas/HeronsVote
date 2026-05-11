class CorOcrParseResult {
  final String name;
  final String studentNo;
  final String email;
  final String program;
  final String college;
  final String yearLevel;
  final String semester;
  final String section;
  final String gender;

  const CorOcrParseResult({
    required this.name,
    required this.studentNo,
    required this.email,
    required this.program,
    required this.college,
    required this.yearLevel,
    required this.semester,
    required this.section,
    required this.gender,
  });
}

enum CorOcrParseError { notUniversityCor, outdatedCor, invalidDetails }

class CorOcrParseException implements Exception {
  final CorOcrParseError type;
  const CorOcrParseException(this.type);
}

class CorOcrParser {
  static CorOcrParseResult parse(String rawText, {required int currentYear}) {
    final normalized = _normalize(rawText);
    final hasStudentNo = RegExp(r'\b[ka]\d{8}\b', caseSensitive: false).hasMatch(normalized);
    final hasUmakEmail = RegExp(r'\b[\w.\-]+@umak\.edu\.ph\b', caseSensitive: false).hasMatch(normalized);
    final hasCollege = normalized.contains('college');
    final hasProgram = normalized.contains('program') || normalized.contains('major');
    final hasSemester = normalized.contains('semester') || normalized.contains('academic year');
    if (!hasStudentNo || !hasUmakEmail || !hasCollege || !hasProgram || !hasSemester) {
      throw const CorOcrParseException(CorOcrParseError.notUniversityCor);
    }

    final ayMatch = RegExp(r'(20\d{2})\s*[-–]\s*(20\d{2})').firstMatch(normalized);
    if (ayMatch == null) {
      throw const CorOcrParseException(CorOcrParseError.outdatedCor);
    }
    final ayStart = int.tryParse(ayMatch.group(1) ?? '');
    final ayEnd = int.tryParse(ayMatch.group(2) ?? '');
    if (ayStart == null || ayEnd == null || ayEnd != ayStart + 1) {
      throw const CorOcrParseException(CorOcrParseError.outdatedCor);
    }
    final isSecondSem = RegExp(r'\b(2nd|second)\s+semester\b', caseSensitive: false).hasMatch(normalized);
    final hasValidAY = ayStart == currentYear || ayStart == currentYear + 1 || (isSecondSem && ayStart == currentYear - 1);
    if (!hasValidAY) {
      throw const CorOcrParseException(CorOcrParseError.outdatedCor);
    }

    final name = _extractFirst(normalized, [
      RegExp(r"\bname\s*[:.]?\s*([a-z,\s.'-]{5,}?)\s+(?=student\s*(?:no|number)\b)", caseSensitive: false),
      RegExp(r"\bstudent\s*name\s*[:.]?\s*([a-z,\s.'-]{5,}?)\s+(?=student\s*(?:no|number)\b)", caseSensitive: false),
    ]);
    final studentNo = _extractFirst(normalized, [
      RegExp(r'\bstudent\s*(?:no|number)\.?\s*[:.]?\s*([ka]\d{8})\b', caseSensitive: false),
      RegExp(r'\b([ka]\d{8})\b', caseSensitive: false),
    ]);
    final email = _extractFirst(normalized, [
      RegExp(r'\bemail\s*[:.]?\s*([\w.\-]+@umak\.edu\.ph)\b', caseSensitive: false),
      RegExp(r'\b([\w.\-]+@umak\.edu\.ph)\b', caseSensitive: false),
    ]);
    final program = _extractFirst(normalized, [
      RegExp(r'\bprogram\s*/?\s*major\s*[:.]?\s*([a-z0-9,&()./\-\s]{5,}?)\s+(?=year\s*level|college|semester|academic\s*year)', caseSensitive: false),
      RegExp(r'\bprogram\s*[:.]?\s*([a-z0-9,&()./\-\s]{5,}?)\s+(?=year\s*level|college|semester|academic\s*year)', caseSensitive: false),
    ]);
    final college = _extractFirst(normalized, [
      RegExp(r'\bcollege\s*(?:of)?\s*[:.]?\s*([a-z0-9,&()./\-\s]{5,}?)\s+(?=program|major|semester|academic\s*year)', caseSensitive: false),
      RegExp(r'\bcollege\s*[:.]?\s*([a-z0-9,&()./\-\s]{5,})', caseSensitive: false),
    ]);
    final yearLevelRaw = _extractFirst(normalized, [
      RegExp(r'\byear\s*level\s*[:.]?\s*([a-z0-9\s]{3,30})', caseSensitive: false),
      RegExp(r'\b(first|second|third|fourth|fifth|\d+(?:st|nd|rd|th)?)\s+year\b', caseSensitive: false),
    ]);
    final semesterLabel = _extractFirst(normalized, [
      RegExp(r'\b(1st|first|2nd|second|summer)\s+semester\b', caseSensitive: false),
      RegExp(r'\bsemester\s*[:.]?\s*([a-z0-9\s]{3,20})', caseSensitive: false),
    ]);
    final sectionRaw = _extractFirst(normalized, [
      RegExp(r'\b([ivx]{1,4}\s*-\s*[a-z0-9]{1,6})\b', caseSensitive: false),
      RegExp(r'\bsection\s*[:.]?\s*([a-z0-9\-]{1,8})\b', caseSensitive: false),
    ]);
    final genderRaw = _extractFirst(normalized, [
      RegExp(r'\bgender\s*[:\-]?\s*(male|female|m|f)\b', caseSensitive: false),
      RegExp(r'\bsex\s*[:\-]?\s*(male|female|m|f)\b', caseSensitive: false),
    ]);

    final nameCap = _capitalizeWords(name);
    final studentNoCap = studentNo.toUpperCase();
    final programCap = _capitalizeWords(program);
    final collegeCap = _capitalizeWords(college);
    final yearLevelCap = _normalizeYearLevel(yearLevelRaw);
    final semester = _normalizeSemester(semesterLabel, ayStart, ayEnd);
    final section = _normalizeSection(sectionRaw);
    final gender = _normalizeGender(genderRaw);

    final studentNoValid = RegExp(r'^[KA]\d{8}$', caseSensitive: false).hasMatch(studentNoCap);
    final emailValid = email.toLowerCase().endsWith('@umak.edu.ph');
    final hasEssentialData = nameCap.isNotEmpty &&
        programCap.isNotEmpty &&
        collegeCap.isNotEmpty &&
        yearLevelCap.isNotEmpty &&
        semester.isNotEmpty;
    if (!studentNoValid || !emailValid || !hasEssentialData) {
      throw const CorOcrParseException(CorOcrParseError.invalidDetails);
    }

    return CorOcrParseResult(
      name: nameCap,
      studentNo: studentNoCap,
      email: email.toLowerCase(),
      program: programCap,
      college: collegeCap,
      yearLevel: yearLevelCap,
      semester: semester,
      section: section,
      gender: gender,
    );
  }

  static String _normalize(String value) {
    return value
        .replaceAll(RegExp(r'[\u2013\u2014]'), '-')
        .replaceAll(RegExp(r'["\n,\r\t]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static String _extractFirst(String source, List<RegExp> patterns) {
    for (final p in patterns) {
      final match = p.firstMatch(source);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
      if (match != null && match.groupCount == 0) {
        return match.group(0)?.trim() ?? '';
      }
    }
    return '';
  }

  static String _capitalizeWords(String input) {
    if (input.isEmpty) return '';
    return input
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ')
        .trim();
  }

  static String _normalizeYearLevel(String raw) {
    if (raw.isEmpty) return '';
    final cleaned = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final explicit = RegExp(r'\b(first|second|third|fourth|fifth|\d+(?:st|nd|rd|th)?)\s+year\b')
        .firstMatch(cleaned)
        ?.group(0);
    if (explicit != null) return _capitalizeWords(explicit);
    return _capitalizeWords(cleaned);
  }

  static String _normalizeSemester(String raw, int ayStart, int ayEnd) {
    if (raw.isEmpty) return '';
    var sem = raw.toLowerCase().trim();
    if (sem.contains('first') || sem.contains('1st')) sem = '1st Semester';
    else if (sem.contains('second') || sem.contains('2nd')) sem = '2nd Semester';
    else if (sem.contains('summer')) sem = 'Summer Semester';
    else sem = _capitalizeWords(sem);
    return '$sem A.Y. $ayStart-$ayEnd';
  }

  static String _normalizeSection(String raw) {
    if (raw.isEmpty) return '';
    return raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  static String _normalizeGender(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'm' || v == 'male') return 'Male';
    if (v == 'f' || v == 'female') return 'Female';
    return 'Unspecified';
  }
}
