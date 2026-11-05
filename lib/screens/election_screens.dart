import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/services/app_repository.dart';
import '../core/theme/app_theme.dart';
import '../models/app_models.dart';
import 'common_widgets.dart';

class ElectionScreen extends StatelessWidget {
  const ElectionScreen({super.key, required this.electionId});

  final String electionId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppRepository>();
    final election = app.electionById(electionId);
    final draft = app.draftVote(electionId);
    final alreadyVoted = app.hasVoted(electionId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        PageHeading(eyebrow: 'Election ballot', title: election.title),
        if (!app.firebaseConfigured) ...[
          const DemoBanner(
            label:
                'Sample ballot. Demo submissions are temporary, not official.',
          ),
          const SizedBox(height: 14),
        ],
        Text(election.description),
        const SizedBox(height: 14),
        if (alreadyVoted)
          SurfaceCard(
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.blue, size: 40),
                const SizedBox(height: 8),
                const Text('A ballot has already been submitted.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/my-votes'),
                  child: const Text('VIEW MY VOTES'),
                ),
              ],
            ),
          )
        else if (!election.isOpen)
          const SurfaceCard(child: Text('Voting for this election is closed.'))
        else ...[
          for (final position in election.positions)
            _PositionCard(
              electionId: election.id,
              position: position,
              selected: draft[position.title],
            ),
          const SizedBox(height: 8),
          PrimaryAction(
            label: 'CONTINUE TO REVIEW',
            icon: Icons.fact_check_outlined,
            onPressed: app.isVoteComplete(electionId)
                ? () => context.go('/confirm/$electionId')
                : () => showMessage(
                    context,
                    'Select one candidate for every position to continue.',
                  ),
          ),
        ],
      ],
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.electionId,
    required this.position,
    required this.selected,
  });

  final String electionId;
  final BallotPosition position;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppRepository>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(position.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            const Text(
              'Select one candidate',
              style: TextStyle(fontSize: 12, color: Color(0xFF758198)),
            ),
            const SizedBox(height: 7),
            for (final candidate in position.candidates)
              _CandidateTile(
                name: candidate,
                selected: selected == candidate,
                onTap: () =>
                    app.selectCandidate(electionId, position.title, candidate),
              ),
          ],
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Material(
      color: selected ? const Color(0xFFE9F3FF) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppTheme.blue : const Color(0xFFE3EBF5),
            ),
          ),
          child: Row(
            children: [
              CandidateAvatar(name: name, size: 40),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppTheme.blue : const Color(0xFFB4C0CE),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ConfirmVoteScreen extends StatefulWidget {
  const ConfirmVoteScreen({super.key, required this.electionId});

  final String electionId;

  @override
  State<ConfirmVoteScreen> createState() => _ConfirmVoteScreenState();
}

class _ConfirmVoteScreenState extends State<ConfirmVoteScreen> {
  String? _error;

  Future<void> _submit() async {
    final app = context.read<AppRepository>();
    try {
      await app.submitVote(widget.electionId);
      if (mounted) context.go('/vote-submitted/${widget.electionId}');
    } catch (error) {
      setState(() => _error = _submissionMessage(error));
    }
  }

  String _submissionMessage(Object error) {
    if (error.toString().contains('already-exists') ||
        error.toString().contains('already submitted')) {
      return 'A ballot has already been submitted for this election.';
    }
    return error.toString().replaceFirst('Bad state: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppRepository>();
    final election = app.electionById(widget.electionId);
    final choices = app.draftVote(widget.electionId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const PageHeading(eyebrow: 'Final review', title: 'Confirm Your Votes'),
        Text(election.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final position in election.positions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.blue),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.title,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          choices[position.title] ?? 'No selection',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        if (!app.firebaseConfigured)
          const DemoBanner(
            label: 'This demo ballot is linked to the sample student. It is not a secret ballot.',
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => context.go('/election/${widget.electionId}'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('BACK / EDIT'),
        ),
        const SizedBox(height: 10),
        PrimaryAction(
          label: 'CONFIRM AND SUBMIT',
          icon: Icons.check_rounded,
          loading: app.isSubmitting,
          onPressed: app.isVoteComplete(widget.electionId) ? _submit : null,
        ),
      ],
    );
  }
}

class VoteSubmittedScreen extends StatelessWidget {
  const VoteSubmittedScreen({super.key, required this.electionId});

  final String electionId;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: AppTheme.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 70,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Vote Submitted!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your vote was submitted successfully.',
            textAlign: TextAlign.center,
          ),
          if (!context.read<AppRepository>().firebaseConfigured) ...[
            const SizedBox(height: 16),
            const DemoBanner(
              label: 'Temporary demo submission only. This is not an official ballot.',
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: 240,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('OK'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/my-votes'),
            child: const Text('View My Votes'),
          ),
        ],
      ),
    ),
  );
}
