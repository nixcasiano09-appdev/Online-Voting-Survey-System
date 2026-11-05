import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/app_repository.dart';
import '../core/theme/app_theme.dart';
import 'common_widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const PageHeading(eyebrow: 'Support center', title: 'Get Help'),
      TextField(
        readOnly: true,
        onTap: () => context.go('/help/faqs'),
        decoration: const InputDecoration(
          hintText: 'Search help topics',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.chevron_right),
        ),
      ),
      const SizedBox(height: 17),
      _HelpLink(
        icon: Icons.quiz_outlined,
        title: 'FAQs',
        subtitle: 'Answers to common questions',
        onTap: () => context.go('/help/faqs'),
      ),
      _HelpLink(
        icon: Icons.rule_rounded,
        title: 'Voting Guidelines',
        subtitle: 'Read eligibility and ballot rules',
        onTap: () => context.go('/help/guidelines'),
      ),
      _HelpLink(
        icon: Icons.contact_support_outlined,
        title: 'Contact Support',
        subtitle: 'Phone, email, and chat options',
        onTap: () => context.go('/help/contact'),
      ),
      _HelpLink(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Chat Support',
        subtitle: 'Check whether live support is available',
        onTap: () => context.go('/help/chat'),
      ),
      _HelpLink(
        icon: Icons.menu_book_outlined,
        title: 'How to Vote',
        subtitle: 'Step-by-step guide',
        onTap: () => context.go('/help/how-to-vote'),
      ),
      _HelpLink(
        icon: Icons.report_problem_outlined,
        title: 'Report a Problem',
        subtitle: 'Send a message to the support team',
        onTap: () => context.go('/help/report'),
      ),
    ],
  );
}

class _HelpLink extends StatelessWidget {
  const _HelpLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.paleBlue,
          child: Icon(icon, color: AppTheme.blue),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.blue),
      ),
    ),
  );
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const faqs = <(String, String)>[
    (
      'How do I log in?',
      'Choose your assigned role, then use the school account credentials issued to you. Accounts are provisioned by authorized staff; this app does not offer public registration.',
    ),
    (
      'How do I cast a vote?',
      'Open an available election, select one candidate for each position, review your choices, and confirm the ballot.',
    ),
    (
      'Can I change my vote after submitting?',
      'No. A submitted ballot is final. Check each selection on the confirmation page before submitting.',
    ),
    (
      'How do I submit a survey?',
      'Open a survey from Home, answer all required questions, then tap Submit Survey.',
    ),
    (
      'When will election results be available?',
      'Results appear after an authorized school administrator publishes them.',
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const PageHeading(eyebrow: 'Support', title: 'FAQs'),
      for (final (question, answer) in faqs)
        Card(
          child: ExpansionTile(
            title: Text(
              question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [Text(answer)],
          ),
        ),
    ],
  );
}

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  static const instructions = [
    'Only eligible students and teachers with an active school account may participate.',
    'Read the election title and position before selecting a candidate.',
    'Choose one candidate per position. Review every selection carefully.',
    'Submit your ballot before the deadline shown by the school.',
    'Each eligible account can submit one ballot per election. A submitted ballot cannot be edited.',
    'Election results are only shown after an administrator officially publishes them.',
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const PageHeading(eyebrow: 'Before you vote', title: 'Voting Guidelines'),
      const Center(
        child: Icon(Icons.fact_check_outlined, size: 76, color: AppTheme.blue),
      ),
      const SizedBox(height: 18),
      for (var index = 0; index < instructions.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.paleBlue,
                foregroundColor: AppTheme.navy,
                child: Text('${index + 1}'),
              ),
              title: Text(instructions[index]),
            ),
          ),
        ),
    ],
  );
}

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  static const supportEmail = 'support@school.edu';
  static const supportPhone = '+15551234567';

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        showMessage(
          context,
          'This contact option is unavailable on this device.',
        );
      }
    } catch (error) {
      if (context.mounted) {
        showMessage(context, 'Could not open this contact option: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const PageHeading(
        eyebrow: 'We are here to help',
        title: 'Contact Support',
      ),
      _HelpLink(
        icon: Icons.chat_outlined,
        title: 'Chat Support',
        subtitle: 'Live support availability',
        onTap: () => context.go('/help/chat'),
      ),
      _HelpLink(
        icon: Icons.phone_outlined,
        title: 'Phone Support',
        subtitle: supportPhone,
        onTap: () => _launch(context, Uri(scheme: 'tel', path: supportPhone)),
      ),
      _HelpLink(
        icon: Icons.email_outlined,
        title: 'Email Support',
        subtitle: supportEmail,
        onTap: () => _launch(
          context,
          Uri(
            scheme: 'mailto',
            path: supportEmail,
            queryParameters: {'subject': 'School Voting System Support'},
          ),
        ),
      ),
      _HelpLink(
        icon: Icons.report_outlined,
        title: 'Report a Problem',
        subtitle: 'Send a support request',
        onTap: () => context.go('/help/report'),
      ),
      const SizedBox(height: 14),
      const DemoBanner(
        label: 'Replace these sample contact details with approved school support channels before deployment.',
      ),
    ],
  );
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: PageHeading(eyebrow: 'Support', title: 'Chat Support'),
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.support_agent,
                      color: AppTheme.blue,
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Live chat is unavailable',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No support service is connected, so messages cannot be delivered. Contact the school support team by phone or email instead.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton(
                      onPressed: () => context.go('/help/contact'),
                      child: const Text('CONTACT SUPPORT'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: 'Chat unavailable',
              suffixIcon: Icon(Icons.send_outlined),
            ),
          ),
        ),
      ),
    ],
  );
}

class HowToVoteScreen extends StatelessWidget {
  const HowToVoteScreen({super.key});

  static const steps = [
    'Choose your assigned role and log in using your school account.',
    'Open the Student Dashboard.',
    'Select an available election.',
    'Choose your preferred candidate for each position.',
    'Review your selected candidates.',
    'Confirm and submit your votes.',
    'View your submitted votes in My Votes.',
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const PageHeading(eyebrow: 'Voting guide', title: 'How to Vote'),
      const Center(
        child: Icon(Icons.how_to_vote_rounded, size: 78, color: AppTheme.blue),
      ),
      const SizedBox(height: 16),
      for (var index = 0; index < steps.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.blue,
                foregroundColor: Colors.white,
                child: Text('${index + 1}'),
              ),
              title: Text(steps[index]),
            ),
          ),
        ),
    ],
  );
}

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  String _category = 'Voting problem';
  XFile? _screenshot;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 80,
      );
      if (mounted && image != null) setState(() => _screenshot = image);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to select an image: $error');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<AppRepository>().submitSupportReport(
        category: _category,
        description: _description.text,
        screenshot: _screenshot,
      );
      if (mounted) context.go('/help/report-submitted');
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const PageHeading(eyebrow: 'Support', title: 'Report a Problem'),
      if (!context.watch<AppRepository>().firebaseConfigured) ...[
        const DemoBanner(
          label: 'Demo reports are not sent or stored permanently.',
        ),
        const SizedBox(height: 13),
      ],
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Problem category'),
              items:
                  const [
                        'Login issue',
                        'Voting problem',
                        'Survey problem',
                        'Accessibility',
                        'Other',
                      ]
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Describe the problem',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().length < 10
                  ? 'Enter at least 10 characters.'
                  : null,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _chooseImage,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _screenshot == null
                    ? 'ATTACH OPTIONAL SCREENSHOT'
                    : 'SCREENSHOT ATTACHED',
              ),
            ),
            if (_screenshot != null) ...[
              const SizedBox(height: 5),
              TextButton(
                onPressed: () => setState(() => _screenshot = null),
                child: const Text('Remove attachment'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryAction(
              label: 'SUBMIT REPORT',
              icon: Icons.send_outlined,
              loading: _sending,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    ],
  );
}

class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.blue,
                size: 66,
              ),
              const SizedBox(height: 14),
              Text(
                'Report Submitted!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                context.read<AppRepository>().firebaseConfigured
                    ? 'Your report has been sent to the support team.'
                    : 'This demo report was not sent or stored permanently.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => context.go('/help'),
                child: const Text('BACK'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
