import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/services/app_repository.dart';
import '../core/theme/app_theme.dart';
import '../models/app_models.dart';
import 'common_widgets.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.surveyId});

  final String surveyId;

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  String? _error;

  Future<void> _submit() async {
    final app = context.read<AppRepository>();
    if (!app.isSurveyComplete(widget.surveyId)) {
      setState(() => _error = 'Please answer all required questions.');
      return;
    }
    try {
      await app.submitSurvey(widget.surveyId);
      if (mounted) context.go('/survey-submitted/${widget.surveyId}');
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppRepository>();
    final survey = app.surveyById(widget.surveyId);
    final alreadySubmitted = app.hasSubmittedSurvey(widget.surveyId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        PageHeading(eyebrow: 'Student survey', title: survey.title),
        Text(survey.description),
        const SizedBox(height: 14),
        if (!app.firebaseConfigured)
          const DemoBanner(
            label:
                'Demo survey responses stay in memory and disappear on exit.',
          ),
        if (alreadySubmitted)
          const SurfaceCard(
            child: Column(
              children: [
                Icon(Icons.check_circle, color: AppTheme.blue, size: 40),
                SizedBox(height: 8),
                Text('You have already submitted this survey.'),
              ],
            ),
          )
        else ...[
          for (var index = 0; index < survey.questions.length; index++)
            _QuestionCard(
              surveyId: survey.id,
              number: index + 1,
              question: survey.questions[index],
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryAction(
            label: 'SUBMIT SURVEY',
            icon: Icons.send_outlined,
            loading: app.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.surveyId,
    required this.number,
    required this.question,
  });

  final String surveyId;
  final int number;
  final SurveyQuestion question;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppRepository>();
    final answer = app.surveyAnswer(surveyId, question.id);
    final selectedOptions = answer is List<String> ? answer : const <String>[];
    return Padding(
      padding: const EdgeInsets.only(top: 13),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$number. ${question.prompt}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (question.textAnswer)
              TextFormField(
                key: ValueKey('${surveyId}_${question.id}'),
                initialValue: answer as String?,
                minLines: 3,
                maxLines: 5,
                onChanged: (value) =>
                    app.setSurveyAnswer(surveyId, question.id, value),
                decoration: const InputDecoration(
                  hintText: 'Type your response',
                  alignLabelWithHint: true,
                ),
              )
            else if (question.multiple)
              for (final option in question.options)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: selectedOptions.contains(option),
                  title: Text(option),
                  onChanged: (checked) {
                    final updated = List<String>.from(selectedOptions);
                    if (checked == true) {
                      updated.add(option);
                    } else {
                      updated.remove(option);
                    }
                    app.setSurveyAnswer(surveyId, question.id, updated);
                  },
                )
            else
              RadioGroup<String>(
                groupValue: answer is String ? answer : null,
                onChanged: (value) =>
                    app.setSurveyAnswer(surveyId, question.id, value),
                child: Column(
                  children: [
                    for (final option in question.options)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: option,
                        title: Text(option),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SurveySubmittedScreen extends StatelessWidget {
  const SurveySubmittedScreen({super.key, required this.surveyId});

  final String surveyId;

  @override
  Widget build(BuildContext context) {
    final survey = context.read<AppRepository>().surveyById(surveyId);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.blue,
                  size: 66,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your answer to the ${survey.title} has been submitted!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!context.read<AppRepository>().firebaseConfigured) ...[
                  const SizedBox(height: 12),
                  const DemoBanner(
                    label: 'Temporary demo response; it was not permanently saved.',
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('DONE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
