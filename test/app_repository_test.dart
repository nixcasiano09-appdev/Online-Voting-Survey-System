import 'package:flutter_test/flutter_test.dart';
import 'package:school_online_voting/core/services/app_repository.dart';

void main() {
  late AppRepository repository;

  setUp(() {
    repository = AppRepository(firebaseConfigured: false);
  });

  tearDown(() {
    repository.dispose();
  });

  test('demo authentication rejects invalid credentials', () async {
    await expectLater(
      repository.signIn(studentId: '2024-1887', password: 'bad-password'),
      throwsA(isA<FormatException>()),
    );
    expect(repository.isAuthenticated, isFalse);

    await repository.signIn(studentId: '2024-1887', password: 'demo1234');
    expect(repository.isAuthenticated, isTrue);
  });

  test(
    'vote requires one choice per position and rejects a duplicate',
    () async {
      await repository.signIn(studentId: '2024-1887', password: 'demo1234');
      const electionId = 'student-council';
      final election = repository.electionById(electionId);
      expect(repository.isVoteComplete(electionId), isFalse);

      for (final position in election.positions) {
        repository.selectCandidate(
          electionId,
          position.title,
          position.candidates.first,
        );
      }

      expect(repository.isVoteComplete(electionId), isTrue);
      await repository.submitVote(electionId);
      expect(repository.hasVoted(electionId), isTrue);
      expect(
        repository.votes.single.selections.length,
        election.positions.length,
      );

      await expectLater(
        repository.submitVote(electionId),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'survey submission requires every answer and cannot be repeated',
    () async {
      await repository.signIn(studentId: '2024-1887', password: 'demo1234');
      const surveyId = 'academic-experience';
      final survey = repository.surveyById(surveyId);
      expect(repository.isSurveyComplete(surveyId), isFalse);

      for (final question in survey.questions) {
        repository.setSurveyAnswer(
          surveyId,
          question.id,
          question.textAnswer
              ? 'A thoughtful response'
              : question.multiple
              ? [question.options.first]
              : question.options.first,
        );
      }
      expect(repository.isSurveyComplete(surveyId), isTrue);

      await repository.submitSurvey(surveyId);
      expect(repository.hasSubmittedSurvey(surveyId), isTrue);
      await expectLater(
        repository.submitSurvey(surveyId),
        throwsA(isA<StateError>()),
      );
    },
  );
}
