import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/app_repository.dart';
import '../core/theme/app_theme.dart';
import '../models/app_models.dart';
import 'common_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _electionTitle = TextEditingController();
  final _electionDescription = TextEditingController();
  final _positions = TextEditingController();
  final _electionEligibility = TextEditingController();
  final _surveyTitle = TextEditingController();
  final _surveyDescription = TextEditingController();
  final _questions = TextEditingController();
  final _surveyEligibility = TextEditingController();
  final _announcementTitle = TextEditingController();
  final _announcementMessage = TextEditingController();
  final _electionFormKey = GlobalKey<FormState>();
  final _surveyFormKey = GlobalKey<FormState>();
  final _electionEligibleRoles = {'student'};
  final _surveyEligibleRoles = {'student'};
  Future<List<Map<String, dynamic>>>? _reports;
  Future<Map<String, dynamic>>? _summary;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final repository = context.read<AppRepository>();
    _reports = repository.loadSupportReports();
    _summary = repository.loadAdminDashboardSummary();
    repository.loadContent();
  }

  @override
  void dispose() {
    _electionTitle.dispose();
    _electionDescription.dispose();
    _positions.dispose();
    _electionEligibility.dispose();
    _surveyTitle.dispose();
    _surveyDescription.dispose();
    _questions.dispose();
    _surveyEligibility.dispose();
    _announcementTitle.dispose();
    _announcementMessage.dispose();
    super.dispose();
  }

  String _slug(String value) => value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  List<String> _eligibleUids(String value) => value
      .split(',')
      .map((uid) => uid.trim())
      .where((uid) => uid.isNotEmpty)
      .toSet()
      .toList();

  List<BallotPosition> _parsePositions(String value) {
    final lines = value.split('\n').where((line) => line.trim().isNotEmpty);
    final positions = <BallotPosition>[];
    for (final line in lines) {
      final separator = line.indexOf(':');
      if (separator <= 0) {
        throw const FormatException(
          'Use one "Position: candidate, candidate" line per position.',
        );
      }
      final title = line.substring(0, separator).trim();
      final candidates = line
          .substring(separator + 1)
          .split(',')
          .map((candidate) => candidate.trim())
          .where((candidate) => candidate.isNotEmpty)
          .toList();
      if (title.isEmpty || candidates.length < 2) {
        throw const FormatException(
          'Each position must have a title and at least two candidates.',
        );
      }
      positions.add(BallotPosition(title, candidates));
    }
    if (positions.isEmpty) {
      throw const FormatException('Add at least one ballot position.');
    }
    return positions;
  }

  List<SurveyQuestion> _parseQuestions(String value) {
    final lines = value.split('\n').where((line) => line.trim().isNotEmpty);
    final questions = <SurveyQuestion>[];
    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length < 2) {
        throw const FormatException(
          'Use "single|Question|options", "multiple|Question|options", or "text|Question".',
        );
      }
      final type = parts[0].trim().toLowerCase();
      final prompt = parts[1].trim();
      final options = parts.length > 2
          ? parts[2]
                .split(',')
                .map((option) => option.trim())
                .where((option) => option.isNotEmpty)
                .toList()
          : <String>[];
      if (prompt.isEmpty ||
          !const {'single', 'multiple', 'rating', 'text'}.contains(type) ||
          (type != 'text' && type != 'rating' && options.length < 2)) {
        throw const FormatException(
          'Check each survey question and its options.',
        );
      }
      questions.add(
        SurveyQuestion(
          id: 'q${questions.length + 1}',
          prompt: prompt,
          options: options,
          multiple: type == 'multiple',
          textAnswer: type == 'text',
          ratingScale: type == 'rating',
        ),
      );
    }
    if (questions.isEmpty) {
      throw const FormatException('Add at least one survey question.');
    }
    return questions;
  }

  Future<(DateTime, DateTime)?> _pickSchedule() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Choose start date',
    );
    if (start == null || !mounted) return null;
    final end = await showDatePicker(
      context: context,
      initialDate: start.add(const Duration(days: 7)),
      firstDate: start,
      lastDate: DateTime(now.year + 5),
      helpText: 'Choose end date',
    );
    if (end == null) return null;
    return (
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  Future<void> _saveElection() async {
    if (!_electionFormKey.currentState!.validate()) return;
    try {
      final positions = _parsePositions(_positions.text);
      final eligible = _eligibleUids(_electionEligibility.text);
      final repository = context.read<AppRepository>();
      final schedule = await _pickSchedule();
      if (schedule == null) return;
      if (!mounted) return;
      setState(() {
        _saving = true;
        _error = null;
      });
      await repository.saveElection(
        electionId: _slug(_electionTitle.text),
        title: _electionTitle.text.trim(),
        description: _electionDescription.text.trim(),
        startDate: schedule.$1,
        endDate: schedule.$2,
        positions: positions,
        eligibleStudentUids: eligible,
        eligibleRoles: _electionEligibleRoles.toList(),
      );
      if (mounted) {
        setState(() => _summary = repository.loadAdminDashboardSummary());
        showMessage(context, 'Election saved.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSurvey() async {
    if (!_surveyFormKey.currentState!.validate()) return;
    try {
      final questions = _parseQuestions(_questions.text);
      final eligible = _eligibleUids(_surveyEligibility.text);
      final repository = context.read<AppRepository>();
      final schedule = await _pickSchedule();
      if (schedule == null) return;
      if (!mounted) return;
      setState(() {
        _saving = true;
        _error = null;
      });
      await repository.saveSurvey(
        surveyId: _slug(_surveyTitle.text),
        title: _surveyTitle.text.trim(),
        description: _surveyDescription.text.trim(),
        startDate: schedule.$1,
        endDate: schedule.$2,
        questions: questions,
        eligibleStudentUids: eligible,
        eligibleRoles: _surveyEligibleRoles.toList(),
      );
      if (mounted) {
        setState(() => _summary = repository.loadAdminDashboardSummary());
        showMessage(context, 'Survey saved.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishAnnouncement() async {
    try {
      await context.read<AppRepository>().publishAnnouncement(
        title: _announcementTitle.text,
        message: _announcementMessage.text,
      );
      _announcementTitle.clear();
      _announcementMessage.clear();
      if (mounted) {
        setState(
          () => _summary = context
              .read<AppRepository>()
              .loadAdminDashboardSummary(),
        );
        showMessage(context, 'Announcement published.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _setReportStatus(String id, String status) async {
    final repository = context.read<AppRepository>();
    try {
      await repository.updateSupportReport(id, status);
      if (!mounted) return;
      setState(() => _reports = repository.loadSupportReports());
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppRepository>();
    if (!app.isAdmin) {
      return const Center(child: Text('Administrator access is required.'));
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageHeading(eyebrow: 'Restricted tools', title: 'Admin Console'),
        DemoBanner(
          label: app.firebaseConfigured
              ? 'Admin actions are checked by Firebase custom claims.'
              : 'Admin functions require a configured Firebase project.',
        ),
        const SizedBox(height: 12),
        _dashboardOverview(),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        _electionEditor(),
        const SizedBox(height: 10),
        _surveyEditor(),
        const SizedBox(height: 10),
        _surveyResponses(),
        const SizedBox(height: 10),
        _announcementEditor(),
        const SizedBox(height: 10),
        _electionResults(),
        const SizedBox(height: 10),
        _supportReports(),
      ],
    );
  }

  Widget _dashboardOverview() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Could not load dashboard summary: ${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(
                    () => _summary = context
                        .read<AppRepository>()
                        .loadAdminDashboardSummary(),
                  ),
                  child: const Text('RETRY'),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data!;
          final activity =
              (summary['recentActivity'] as List? ?? const <dynamic>[])
                  .whereType<Map>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System overview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summaryStat('Students', summary['totalStudents']),
                  _summaryStat('Teachers', summary['totalTeachers']),
                  _summaryStat('Elections', summary['totalElections']),
                  _summaryStat('Surveys', summary['totalSurveys']),
                  _summaryStat('Active', summary['activeActivities']),
                  _summaryStat('Completed', summary['completedActivities']),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Recent announcements',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (activity.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No recent announcements.'),
                )
              else
                for (final item in activity)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_none_rounded),
                    title: Text(item['title'] as String? ?? 'Announcement'),
                    subtitle: Text(
                      item['message'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: item['createdAt'] is int
                        ? Text(
                            DateFormat.MMMd().format(
                              DateTime.fromMillisecondsSinceEpoch(
                                item['createdAt'] as int,
                              ).toLocal(),
                            ),
                          )
                        : null,
                  ),
            ],
          );
        },
      ),
    ),
  );

  Widget _summaryStat(String label, dynamic value) => SizedBox(
    width: 100,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.paleBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value?.toString() ?? '0',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );

  Widget _electionEditor() => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.how_to_vote_outlined),
      title: const Text('Create / update election'),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _electionFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _electionTitle,
                decoration: const InputDecoration(labelText: 'Election name'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _electionDescription,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _positions,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Positions and candidates',
                  hintText: 'President: Candidate One, Candidate Two\nSecretary: Candidate Three, Candidate Four',
                  alignLabelWithHint: true,
                ),
                validator: _required,
              ),
              const SizedBox(height: 10),
              _eligibleRolesField(
                selected: _electionEligibleRoles,
                onChanged: (role, selected) =>
                    _toggleEligibleRole(_electionEligibleRoles, role, selected),
              ),
              TextFormField(
                controller: _electionEligibility,
                decoration: const InputDecoration(
                  labelText: 'Additional eligible account UIDs (optional)',
                  hintText: 'uid1, uid2, uid3',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose eligible roles above. Optionally add specific provisioned account UIDs.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              PrimaryAction(
                label: 'SAVE ELECTION',
                loading: _saving,
                onPressed: _saveElection,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _surveyEditor() => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.assignment_outlined),
      title: const Text('Create / update survey'),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _surveyFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _surveyTitle,
                decoration: const InputDecoration(labelText: 'Survey name'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _surveyDescription,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _questions,
                minLines: 5,
                maxLines: 9,
                decoration: const InputDecoration(
                  labelText: 'Questions',
                  hintText: 'single|How satisfied are you?|Very, Satisfied, Neutral\nmultiple|Which spaces do you use?|Library, Lab\nrating|Rate your experience from 1 to 5\ntext|What should improve?',
                  alignLabelWithHint: true,
                ),
                validator: _required,
              ),
              const SizedBox(height: 10),
              _eligibleRolesField(
                selected: _surveyEligibleRoles,
                onChanged: (role, selected) =>
                    _toggleEligibleRole(_surveyEligibleRoles, role, selected),
              ),
              TextFormField(
                controller: _surveyEligibility,
                decoration: const InputDecoration(
                  labelText: 'Additional eligible account UIDs (optional)',
                  hintText: 'uid1, uid2, uid3',
                ),
              ),
              const SizedBox(height: 12),
              PrimaryAction(
                label: 'SAVE SURVEY',
                loading: _saving,
                onPressed: _saveSurvey,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _announcementEditor() => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: const Text('Publish announcement'),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _announcementTitle,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _announcementMessage,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        const SizedBox(height: 12),
        PrimaryAction(
          label: 'PUBLISH TO ALL STUDENTS',
          icon: Icons.send_outlined,
          onPressed: _publishAnnouncement,
        ),
      ],
    ),
  );

  Widget _surveyResponses() {
    final surveys = context.watch<AppRepository>().surveys;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.rate_review_outlined),
        title: const Text('Review survey responses'),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          if (surveys.isEmpty) const Text('No active surveys are available.'),
          for (final survey in surveys)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(survey.title),
              trailing: TextButton(
                onPressed: () => _showSurveyResponses(survey.id, survey.title),
                child: const Text('REVIEW'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showSurveyResponses(String surveyId, String title) async {
    final responses = context.read<AppRepository>().loadSurveyResponses(
      surveyId,
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: responses,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Could not load responses: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Text('No responses have been submitted.');
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  for (var index = 0; index < snapshot.data!.length; index++)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Response ${index + 1}'),
                            const SizedBox(height: 6),
                            for (final answer
                                in (snapshot.data![index]['answers'] as Map)
                                    .entries)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${answer.key}: ${answer.value is List ? (answer.value as List).join(', ') : answer.value}',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _electionResults() {
    final elections = context.watch<AppRepository>().elections;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.bar_chart_rounded),
        title: const Text('Manage election results'),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          if (elections.isEmpty) const Text('No elections are available.'),
          for (final election in elections)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(election.title),
              subtitle: Text(
                election.resultsPublished
                    ? 'Results published'
                    : 'Results are hidden from students',
              ),
              trailing: election.resultsPublished
                  ? const Icon(Icons.check_circle, color: AppTheme.blue)
                  : TextButton(
                      onPressed: () async {
                        try {
                          await context
                              .read<AppRepository>()
                              .publishElectionResults(election.id);
                          if (mounted) {
                            setState(
                              () => _summary = context
                                  .read<AppRepository>()
                                  .loadAdminDashboardSummary(),
                            );
                            showMessage(context, 'Results published.');
                          }
                        } catch (error) {
                          setState(() => _error = error.toString());
                        }
                      },
                      child: const Text('PUBLISH'),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _supportReports() => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.support_agent),
      title: const Text('Open support reports'),
      onExpansionChanged: (expanded) {
        if (expanded) {
          setState(
            () => _reports = context.read<AppRepository>().loadSupportReports(),
          );
        }
      },
      childrenPadding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _reports,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Could not load reports: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return const Text('No open support reports.');
            }
            return Column(
              children: snapshot.data!.map((report) {
                final id = report['id'] as String;
                return Card(
                  child: ListTile(
                    title: Text(report['category'] as String? ?? 'Report'),
                    subtitle: Text(
                      report['description'] as String? ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (status) => _setReportStatus(id, status),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'in_review',
                          child: Text('Mark in review'),
                        ),
                        PopupMenuItem(
                          value: 'resolved',
                          child: Text('Resolve'),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  Widget _eligibleRolesField({
    required Set<String> selected,
    required void Function(String role, bool? selected) onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: Text('Eligible roles'),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Students'),
        value: selected.contains('student'),
        onChanged: (value) => onChanged('student', value),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Teachers'),
        value: selected.contains('teacher'),
        onChanged: (value) => onChanged('teacher', value),
      ),
    ],
  );

  void _toggleEligibleRole(Set<String> roles, String role, bool? selected) {
    setState(() {
      if (selected == true) {
        roles.add(role);
      } else if (roles.length > 1) {
        roles.remove(role);
      }
    });
  }
}
