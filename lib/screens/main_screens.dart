import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/services/app_repository.dart';
import '../core/theme/app_theme.dart';
import '../models/app_models.dart';
import 'common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppRepository>().loadContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppRepository>();
    if (app.isLoadingContent && app.elections.isEmpty && app.surveys.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        if (app.contentError != null) ...[
          DemoBanner(label: app.contentError!),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => app.loadContent(force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!app.firebaseConfigured) ...[
          DemoBanner(label: app.backendLabel),
          const SizedBox(height: 17),
        ],
        Text('Welcome back,', style: Theme.of(context).textTheme.bodyMedium),
        Text(
          app.student.fullName.split(' ').first,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 18),
        if (app.elections.isNotEmpty) ...[
          _DashboardSpotlight(
            election: app.elections.first,
            completed: app.hasVoted(app.elections.first.id),
          ),
          const SizedBox(height: 20),
        ],
        SectionTitle('Elections'),
        if (app.elections.isEmpty)
          const _NoActivities(
            message: 'There are no open elections right now.',
          ),
        for (final election in app.elections)
          _ActivityCard(
            icon: Icons.how_to_vote_outlined,
            eyebrow: 'Election',
            title: election.title,
            subtitle: election.isOpen ? 'Voting is open' : 'Voting is closed',
            trailing: app.hasVoted(election.id)
                ? 'Voted'
                : election.isOpen
                ? 'VIEW'
                : 'Closed',
            onTap: () => context.go('/election/${election.id}'),
          ),
        const SizedBox(height: 16),
        SectionTitle('Surveys'),
        if (app.surveys.isEmpty)
          const _NoActivities(message: 'There are no open surveys right now.'),
        for (final survey in app.surveys)
          _ActivityCard(
            icon: Icons.assignment_outlined,
            eyebrow: 'Survey',
            title: survey.title,
            subtitle: survey.description,
            trailing: app.hasSubmittedSurvey(survey.id) ? 'Done' : 'OPEN',
            onTap: () => context.go('/survey/${survey.id}'),
          ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => context.go('/my-votes'),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('View My Votes and Responses'),
        ),
      ],
    );
  }
}

class _DashboardSpotlight extends StatelessWidget {
  const _DashboardSpotlight({required this.election, required this.completed});

  final Election election;
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE2F1FF), Color(0xFFF7FBFF)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD4E7FC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign_outlined, color: AppTheme.blue),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'ACTIVE ELECTION',
                style: TextStyle(
                  color: AppTheme.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (!completed)
              const Chip(
                visualDensity: VisualDensity.compact,
                label: Text('OPEN'),
                backgroundColor: Colors.white,
              ),
          ],
        ),
        const SizedBox(height: 9),
        Text(election.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(election.description),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: completed
                ? () => context.go('/my-votes')
                : () => context.go('/election/${election.id}'),
            child: Text(completed ? 'VIEW MY VOTE' : 'VOTE NOW'),
          ),
        ),
      ],
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppTheme.paleBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppTheme.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF758198),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: const TextStyle(
              color: AppTheme.blue,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right, color: AppTheme.blue),
        ],
      ),
    ),
  );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<AppRepository>().notifications;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageHeading(eyebrow: 'Updates', title: 'Notifications'),
        for (final notification in notifications)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: SurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(notification.message),
                        const SizedBox(height: 8),
                        Text(
                          notification.time,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final published = context
        .watch<AppRepository>()
        .elections
        .where((election) => election.resultsPublished)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageHeading(eyebrow: 'Election updates', title: 'Results'),
        if (published.isEmpty) ...[
          const SizedBox(height: 40),
          const Icon(Icons.bar_chart_rounded, size: 74, color: AppTheme.blue),
          const SizedBox(height: 18),
          Text(
            'Results are not out yet!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Election results will be available here after they are officially published by the school.',
            textAlign: TextAlign.center,
          ),
        ] else
          for (final election in published)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      election.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Official results · ${election.totalBallots} ballots'),
                    const SizedBox(height: 10),
                    for (final entry in election.publishedResults.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 6),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...entry.value.entries.map((candidate) {
                        final total = entry.value.values.fold<int>(
                          0,
                          (sum, count) => sum + count,
                        );
                        final percent = total == 0
                            ? 0.0
                            : candidate.value / total;
                        final winner =
                            candidate.value ==
                                entry.value.values.reduce(
                                  (first, second) =>
                                      first > second ? first : second,
                                ) &&
                            candidate.value > 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${candidate.key}${winner ? ' · Winner' : ''}',
                                    ),
                                  ),
                                  Text(
                                    '${candidate.value} · ${(percent * 100).toStringAsFixed(1)}%',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(value: percent),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AppRepository>().student;
    final fields = <String, String>{
      'Student ID': student.studentId,
      'Course / Program': student.course,
      'Year level': student.yearLevel,
      'Section': student.section,
      'Email address': student.email,
    };
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageHeading(eyebrow: 'Account', title: 'My Profile'),
        SurfaceCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: AppTheme.paleBlue,
                child: Icon(Icons.person, size: 44, color: AppTheme.blue),
              ),
              const SizedBox(height: 12),
              Text(
                student.fullName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              for (final entry in fields.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  subtitle: Text(
                    entry.value.isEmpty ? 'Not provided' : entry.value,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entries = context
        .watch<AppRepository>()
        .history
        .where(
          (entry) => (entry['title'] as String).toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageHeading(eyebrow: 'Your activity', title: 'History'),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search your activity',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          const _EmptyRecords(
            title: 'No activity yet',
            message: 'Your completed votes and surveys will appear here.',
          ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.paleBlue,
                  child: Icon(Icons.check, color: AppTheme.blue),
                ),
                title: Text(entry['title'] as String),
                subtitle: Text(entry['kind'] as String),
                trailing: Text(
                  DateFormat.yMMMd().format(entry['date'] as DateTime),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MyVotesScreen extends StatelessWidget {
  const MyVotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppRepository>();
    final records = app.votes;
    final surveys = app.surveyRecords;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageHeading(eyebrow: 'Your records', title: 'My Votes'),
        if (!app.firebaseConfigured) ...[
          const DemoBanner(
            label: 'Demo records belong to this temporary app session only.',
          ),
          const SizedBox(height: 12),
        ],
        if (records.isEmpty)
          const _EmptyRecords(
            title: 'No submitted votes yet',
            message:
                'Once you confirm an election ballot, it will appear here.',
          ),
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.electionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted ${DateFormat.yMMMd().add_jm().format(record.submittedAt)} · Recorded',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 20),
                  for (final selection in record.selections.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Expanded(child: Text(selection.key)),
                          Text(
                            selection.value,
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SectionTitle('Submitted surveys'),
        if (surveys.isEmpty)
          const Text('Your submitted survey confirmations will appear here.'),
        for (final survey in surveys)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: SurfaceCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(survey.title),
                subtitle: Text(
                  'Submitted ${DateFormat.yMMMd().format(survey.submittedAt)}',
                ),
                trailing: const Icon(Icons.check_circle, color: AppTheme.blue),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 54, color: AppTheme.blue),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _NoActivities extends StatelessWidget {
  const _NoActivities({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Text(message),
  );
}
