class Student {
  const Student({
    required this.uid,
    required this.studentId,
    required this.fullName,
    required this.course,
    required this.yearLevel,
    required this.section,
    required this.email,
    this.role = 'student',
  });

  final String uid;
  final String studentId;
  final String fullName;
  final String course;
  final String yearLevel;
  final String section;
  final String email;
  final String role;
}

class Election {
  const Election({
    required this.id,
    required this.title,
    required this.description,
    required this.positions,
    this.isOpen = true,
    this.resultsPublished = false,
    this.publishedResults = const {},
    this.totalBallots = 0,
  });

  final String id;
  final String title;
  final String description;
  final List<BallotPosition> positions;
  final bool isOpen;
  final bool resultsPublished;
  final Map<String, Map<String, int>> publishedResults;
  final int totalBallots;
}

class BallotPosition {
  const BallotPosition(this.title, this.candidates);

  final String title;
  final List<String> candidates;
}

class VoteRecord {
  const VoteRecord({
    required this.electionId,
    required this.electionTitle,
    required this.selections,
    required this.submittedAt,
  });

  final String electionId;
  final String electionTitle;
  final Map<String, String> selections;
  final DateTime submittedAt;
}

class Survey {
  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.isOpen = true,
  });

  final String id;
  final String title;
  final String description;
  final List<SurveyQuestion> questions;
  final bool isOpen;
}

class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.multiple = false,
    this.textAnswer = false,
    this.ratingScale = false,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final bool multiple;
  final bool textAnswer;
  final bool ratingScale;
}

class SurveyRecord {
  const SurveyRecord({
    required this.surveyId,
    required this.title,
    required this.submittedAt,
  });

  final String surveyId;
  final String title;
  final DateTime submittedAt;
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.message,
    required this.time,
  });

  final String title;
  final String message;
  final String time;
}
