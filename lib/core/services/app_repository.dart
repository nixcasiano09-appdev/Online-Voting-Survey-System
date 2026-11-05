import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_models.dart';
import 'demo_data.dart';

class AppRepository extends ChangeNotifier {
  AppRepository({required this.firebaseConfigured}) {
    if (firebaseConfigured) {
      _elections = [];
      _surveys = [];
      _notifications = [];
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        _onAuthStateChanged,
      );
    }
  }

  final bool firebaseConfigured;
  StreamSubscription<User?>? _authSubscription;
  final Map<String, Map<String, String>> _draftVotes = {};
  final Map<String, Map<String, dynamic>> _draftSurveys = {};
  final List<VoteRecord> _demoVotes = [];
  final List<SurveyRecord> _demoSurveyRecords = [];
  List<Election> _elections = demoElections;
  List<Survey> _surveys = demoSurveys;
  List<AppNotification> _notifications = demoNotifications;
  List<VoteRecord> _firebaseVotes = [];
  List<SurveyRecord> _firebaseSurveyRecords = [];
  Student? _student;
  bool _isSubmitting = false;
  bool _isLoadingContent = false;
  bool _hasLoadedContent = false;
  String? _contentError;
  String? _authError;

  bool get isAuthenticated => _student != null;
  bool get isAdmin => _student?.role == 'admin';
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingContent => _isLoadingContent;
  String? get contentError => _contentError;
  String? get authError => _authError;
  Student get student => _student ?? demoStudent;
  String get backendLabel => firebaseConfigured
      ? 'Connected to Firebase'
      : 'DEMO MODE · data is temporary';
  List<Election> get elections => List.unmodifiable(_elections);
  List<Survey> get surveys => List.unmodifiable(_surveys);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<VoteRecord> get votes =>
      List.unmodifiable(firebaseConfigured ? _firebaseVotes : _demoVotes);
  List<SurveyRecord> get surveyRecords => List.unmodifiable(
    firebaseConfigured ? _firebaseSurveyRecords : _demoSurveyRecords,
  );
  List<Map<String, dynamic>> get history => [
    ...votes.map(
      (record) => {
        'title': record.electionTitle,
        'date': record.submittedAt,
        'kind': 'Election ballot',
      },
    ),
    ...surveyRecords.map(
      (record) => {
        'title': record.title,
        'date': record.submittedAt,
        'kind': 'Survey response',
      },
    ),
  ];

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _student = null;
      _authError = null;
      notifyListeners();
      return;
    }
    if (_student?.uid == user.uid) return;
    try {
      final record = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();
      if (!record.exists) {
        await FirebaseAuth.instance.signOut();
        _authError = 'This account has no provisioned student record.';
        notifyListeners();
        return;
      }
      final data = record.data()!;
      final token = await user.getIdTokenResult();
      _student = Student(
        uid: user.uid,
        studentId: data['studentId'] as String? ?? '',
        fullName: data['fullName'] as String? ?? 'Student',
        course: data['course'] as String? ?? '',
        yearLevel: data['yearLevel'] as String? ?? '',
        section: data['section'] as String? ?? '',
        email: data['email'] as String? ?? '',
        role: token.claims?['admin'] == true ? 'admin' : 'student',
      );
      _authError = null;
      notifyListeners();
      await loadContent();
    } catch (error) {
      _authError = 'Could not restore the signed-in account: $error';
      notifyListeners();
    }
  }

  Election electionById(String id) =>
      _elections.firstWhere((election) => election.id == id);

  Survey surveyById(String id) =>
      _surveys.firstWhere((survey) => survey.id == id);

  bool hasVoted(String electionId) =>
      votes.any((vote) => vote.electionId == electionId);

  bool hasSubmittedSurvey(String surveyId) =>
      surveyRecords.any((record) => record.surveyId == surveyId);

  Map<String, String> draftVote(String electionId) =>
      Map.unmodifiable(_draftVotes[electionId] ?? const {});

  void selectCandidate(String electionId, String position, String candidate) {
    _draftVotes.putIfAbsent(electionId, () => {})[position] = candidate;
    notifyListeners();
  }

  bool isVoteComplete(String electionId) {
    final election = electionById(electionId);
    final draft = _draftVotes[electionId] ?? const {};
    return election.positions.every(
      (position) => draft.containsKey(position.title),
    );
  }

  Future<void> loadContent({bool force = false}) async {
    if (!firebaseConfigured ||
        _isLoadingContent ||
        (_hasLoadedContent && !force)) {
      return;
    }
    _isLoadingContent = true;
    _contentError = null;
    notifyListeners();
    try {
      final firestore = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final electionSnapshots = await firestore
          .collection('elections')
          .where('status', whereIn: ['active', 'completed'])
          .get();
      _elections = electionSnapshots.docs.map((document) {
        final data = document.data();
        final start = _asDate(data['startDate']);
        final end = _asDate(data['endDate']);
        final now = DateTime.now();
        return Election(
          id: document.id,
          title: data['title'] as String? ?? document.id,
          description: data['description'] as String? ?? '',
          positions: _parsePositions(data['positions']),
          isOpen:
              start != null &&
              end != null &&
              !now.isBefore(start) &&
              !now.isAfter(end),
          resultsPublished: data['resultsPublished'] == true,
          publishedResults: _parseResults(data['publishedResults']),
          totalBallots: data['totalBallots'] as int? ?? 0,
        );
      }).toList();
      final publishedSnapshots = await firestore
          .collection('elections')
          .where('resultsPublished', isEqualTo: true)
          .get();
      final electionIds = _elections.map((election) => election.id).toSet();
      for (final document in publishedSnapshots.docs) {
        if (electionIds.add(document.id)) {
          final data = document.data();
          _elections.add(
            Election(
              id: document.id,
              title: data['title'] as String? ?? document.id,
              description: data['description'] as String? ?? '',
              positions: _parsePositions(data['positions']),
              isOpen: false,
              resultsPublished: true,
              publishedResults: _parseResults(data['publishedResults']),
              totalBallots: data['totalBallots'] as int? ?? 0,
            ),
          );
        }
      }

      final surveySnapshots = await firestore
          .collection('surveys')
          .where('status', isEqualTo: 'active')
          .get();
      _surveys = surveySnapshots.docs.map((document) {
        final data = document.data();
        final start = _asDate(data['startDate']);
        final end = _asDate(data['endDate']);
        final now = DateTime.now();
        return Survey(
          id: document.id,
          title: data['title'] as String? ?? document.id,
          description: data['description'] as String? ?? '',
          questions: _parseQuestions(data['questions']),
          isOpen:
              start != null &&
              end != null &&
              !now.isBefore(start) &&
              !now.isAfter(end),
        );
      }).toList();

      final voteSnapshots = await firestore
          .collection('votes')
          .where('studentUid', isEqualTo: uid)
          .get();
      _firebaseVotes = voteSnapshots.docs.map((document) {
        final data = document.data();
        return VoteRecord(
          electionId: data['electionId'] as String? ?? '',
          electionTitle: data['electionTitle'] as String? ?? 'Election',
          selections: Map<String, String>.from(
            data['selectedCandidates'] as Map? ?? const {},
          ),
          submittedAt: _asDate(data['submittedAt']) ?? DateTime.now(),
        );
      }).toList()..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      final responseSnapshots = await firestore
          .collection('survey_responses')
          .where('studentUid', isEqualTo: uid)
          .get();
      _firebaseSurveyRecords = responseSnapshots.docs.map((document) {
        final data = document.data();
        return SurveyRecord(
          surveyId: data['surveyId'] as String? ?? '',
          title: data['surveyTitle'] as String? ?? 'Survey',
          submittedAt: _asDate(data['submittedAt']) ?? DateTime.now(),
        );
      }).toList()..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      final notificationSnapshots = await firestore
          .collection('notifications')
          .where('targetAudience', whereIn: ['all', uid])
          .get();
      _notifications = notificationSnapshots.docs.map((document) {
        final data = document.data();
        return AppNotification(
          title: data['title'] as String? ?? 'Announcement',
          message: data['message'] as String? ?? '',
          time: _asDate(data['createdAt'])?.toLocal().toString() ?? '',
        );
      }).toList()..sort((a, b) => b.time.compareTo(a.time));
      _hasLoadedContent = true;
    } catch (error) {
      _contentError = 'Could not load school data: $error';
    } finally {
      _isLoadingContent = false;
      notifyListeners();
    }
  }

  Map<String, Map<String, int>> _parseResults(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((position, candidates) {
      if (candidates is! Map) {
        return MapEntry(position.toString(), <String, int>{});
      }
      return MapEntry(
        position.toString(),
        candidates.map(
          (candidate, value) => MapEntry(candidate.toString(), value as int),
        ),
      );
    });
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  List<BallotPosition> _parsePositions(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (position) => BallotPosition(
            position['title'] as String? ?? 'Position',
            (position['candidates'] as List? ?? const [])
                .map(
                  (candidate) => candidate is String
                      ? candidate
                      : (candidate as Map)['fullName'] as String? ?? '',
                )
                .where((candidate) => candidate.isNotEmpty)
                .toList(),
          ),
        )
        .toList();
  }

  List<SurveyQuestion> _parseQuestions(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((question) {
      final type = question['type'] as String? ?? 'single';
      return SurveyQuestion(
        id: question['id'] as String? ?? '',
        prompt: question['prompt'] as String? ?? '',
        options: (question['options'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        multiple: type == 'multiple' || question['multiple'] == true,
        textAnswer: type == 'text' || question['textAnswer'] == true,
      );
    }).toList();
  }

  Future<void> signIn({
    required String studentId,
    required String password,
  }) async {
    final normalizedId = studentId.trim();
    if (normalizedId.isEmpty || password.isEmpty) {
      throw const FormatException('Enter your Student ID and password.');
    }

    if (!firebaseConfigured) {
      if (normalizedId != demoStudent.studentId || password != 'demo1234') {
        throw const FormatException(
          'Demo login: use Student ID 2024-1887 and password demo1234.',
        );
      }
      _student = demoStudent;
      notifyListeners();
      return;
    }

    final authEmail = _studentIdAlias(normalizedId);
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: authEmail,
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) {
      throw StateError('Authentication succeeded without a user identifier.');
    }

    final record = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .get();
    if (!record.exists) {
      await FirebaseAuth.instance.signOut();
      throw StateError('This authenticated account has no student record.');
    }
    final data = record.data()!;
    final token = await credential.user!.getIdTokenResult();
    _student = Student(
      uid: uid,
      studentId: data['studentId'] as String? ?? normalizedId,
      fullName: data['fullName'] as String? ?? 'Student',
      course: data['course'] as String? ?? '',
      yearLevel: data['yearLevel'] as String? ?? '',
      section: data['section'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: token.claims?['admin'] == true ? 'admin' : 'student',
    );
    notifyListeners();
  }

  Future<void> saveElection({
    required String electionId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required List<BallotPosition> positions,
    required List<String> eligibleStudentUids,
  }) async {
    if (!isAdmin || !firebaseConfigured) {
      throw StateError('Only a connected administrator can manage elections.');
    }
    await FirebaseFunctions.instance.httpsCallable('upsertElection').call({
      'electionId': electionId,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': 'active',
      'positions': positions
          .map(
            (position) => {
              'title': position.title,
              'candidates': position.candidates,
            },
          )
          .toList(),
      'eligibleStudentUids': eligibleStudentUids,
    });
    await loadContent(force: true);
  }

  Future<void> saveSurvey({
    required String surveyId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required List<SurveyQuestion> questions,
    required List<String> eligibleStudentUids,
  }) async {
    if (!isAdmin || !firebaseConfigured) {
      throw StateError('Only a connected administrator can manage surveys.');
    }
    await FirebaseFunctions.instance.httpsCallable('upsertSurvey').call({
      'surveyId': surveyId,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': 'active',
      'questions': questions
          .map(
            (question) => {
              'id': question.id,
              'prompt': question.prompt,
              'options': question.options,
              'type': question.textAnswer
                  ? 'text'
                  : question.multiple
                  ? 'multiple'
                  : 'single',
              'required': true,
            },
          )
          .toList(),
      'eligibleStudentUids': eligibleStudentUids,
    });
    await loadContent(force: true);
  }

  Future<void> publishElectionResults(String electionId) async {
    if (!isAdmin || !firebaseConfigured) {
      throw StateError('Only a connected administrator can publish results.');
    }
    await FirebaseFunctions.instance.httpsCallable('publishResults').call({
      'electionId': electionId,
    });
    await loadContent(force: true);
  }

  Future<List<Map<String, dynamic>>> loadSupportReports() async {
    if (!isAdmin || !firebaseConfigured) {
      throw StateError('Only a connected administrator can review reports.');
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('support_reports')
        .where('status', isEqualTo: 'open')
        .get();
    return snapshot.docs
        .map((document) => {'id': document.id, ...document.data()})
        .toList();
  }

  Future<void> updateSupportReport(String reportId, String status) async {
    if (!isAdmin || !firebaseConfigured) {
      throw StateError('Only a connected administrator can update reports.');
    }
    if (!const {'in_review', 'resolved'}.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported report status');
    }
    await FirebaseFirestore.instance
        .collection('support_reports')
        .doc(reportId)
        .update({'status': status});
  }

  Future<void> publishAnnouncement({
    required String title,
    required String message,
    String targetAudience = 'all',
  }) async {
    if (!isAdmin || !firebaseConfigured) {
      throw StateError(
        'Only a connected administrator can publish announcements.',
      );
    }
    await FirebaseFunctions.instance.httpsCallable('publishAnnouncement').call({
      'title': title,
      'message': message,
      'targetAudience': targetAudience,
    });
    await loadContent(force: true);
  }

  Future<List<Map<String, dynamic>>> loadSurveyResponses(
    String surveyId,
  ) async {
    if (!isAdmin || !firebaseConfigured) {
      throw StateError('Only a connected administrator can review responses.');
    }
    final result = await FirebaseFunctions.instance
        .httpsCallable('listSurveyResponses')
        .call({'surveyId': surveyId});
    return (result.data as List)
        .whereType<Map>()
        .map((response) => Map<String, dynamic>.from(response))
        .toList();
  }

  String _studentIdAlias(String studentId) {
    final normalized = studentId.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '',
    );
    if (normalized.isEmpty) {
      throw const FormatException('Enter a valid Student ID.');
    }
    return '$normalized@students.school.invalid';
  }

  Future<void> signOut() async {
    if (firebaseConfigured) await FirebaseAuth.instance.signOut();
    _student = null;
    _elections = firebaseConfigured ? [] : demoElections;
    _surveys = firebaseConfigured ? [] : demoSurveys;
    _notifications = firebaseConfigured ? [] : demoNotifications;
    _firebaseVotes.clear();
    _firebaseSurveyRecords.clear();
    _hasLoadedContent = false;
    _draftVotes.clear();
    _draftSurveys.clear();
    notifyListeners();
  }

  Future<void> submitVote(String electionId) async {
    final election = electionById(electionId);
    final selections = Map<String, String>.from(
      _draftVotes[electionId] ?? const {},
    );
    if (!election.isOpen) throw StateError('This election is not open.');
    if (hasVoted(electionId)) {
      throw StateError(
        'A ballot has already been submitted for this election.',
      );
    }
    if (!isVoteComplete(electionId)) {
      throw StateError(
        'Select one candidate for every position before continuing.',
      );
    }
    _isSubmitting = true;
    notifyListeners();
    try {
      if (firebaseConfigured) {
        await FirebaseFunctions.instance.httpsCallable('submitBallot').call({
          'electionId': electionId,
          'selectedCandidates': selections,
        });
        await loadContent(force: true);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _demoVotes.insert(
          0,
          VoteRecord(
            electionId: election.id,
            electionTitle: election.title,
            selections: selections,
            submittedAt: DateTime.now(),
          ),
        );
      }
      _draftVotes.remove(electionId);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  dynamic surveyAnswer(String surveyId, String questionId) =>
      _draftSurveys[surveyId]?[questionId];

  void setSurveyAnswer(String surveyId, String questionId, dynamic value) {
    _draftSurveys.putIfAbsent(surveyId, () => {})[questionId] = value;
    notifyListeners();
  }

  bool isSurveyComplete(String surveyId) {
    final survey = surveyById(surveyId);
    final answers = _draftSurveys[surveyId] ?? const {};
    return survey.questions.every((question) {
      final answer = answers[question.id];
      if (answer is String) return answer.trim().isNotEmpty;
      if (answer is List) return answer.isNotEmpty;
      return false;
    });
  }

  Future<void> submitSurvey(String surveyId) async {
    if (!surveyById(surveyId).isOpen) {
      throw StateError('This survey is no longer accepting responses.');
    }
    if (hasSubmittedSurvey(surveyId)) {
      throw StateError(
        'A response has already been submitted for this survey.',
      );
    }
    if (!isSurveyComplete(surveyId)) {
      throw StateError('Please answer all required questions.');
    }
    _isSubmitting = true;
    notifyListeners();
    try {
      final answers = Map<String, dynamic>.from(_draftSurveys[surveyId]!);
      if (firebaseConfigured) {
        await FirebaseFunctions.instance.httpsCallable('submitSurvey').call({
          'surveyId': surveyId,
          'answers': answers,
        });
        await loadContent(force: true);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _demoSurveyRecords.insert(
          0,
          SurveyRecord(
            surveyId: surveyId,
            title: surveyById(surveyId).title,
            submittedAt: DateTime.now(),
          ),
        );
      }
      _draftSurveys.remove(surveyId);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> submitSupportReport({
    required String category,
    required String description,
    XFile? screenshot,
  }) async {
    if (description.trim().isEmpty) {
      throw const FormatException('Describe the problem before submitting.');
    }
    if (!firebaseConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    String? screenshotUrl;
    if (screenshot != null) {
      final ref = FirebaseStorage.instance.ref(
        'support_reports/$uid/${DateTime.now().millisecondsSinceEpoch}',
      );
      await ref.putData(
        await screenshot.readAsBytes(),
        SettableMetadata(contentType: screenshot.mimeType ?? 'image/jpeg'),
      );
      screenshotUrl = await ref.getDownloadURL();
    }
    await FirebaseFirestore.instance.collection('support_reports').add({
      'studentUid': uid,
      'category': category,
      'description': description.trim(),
      'screenshotUrl': screenshotUrl,
      'status': 'open',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
