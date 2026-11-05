import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/services/app_repository.dart';
import 'core/theme/app_theme.dart';
import 'screens/admin_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/election_screens.dart';
import 'screens/main_screens.dart';
import 'screens/shell.dart';
import 'screens/support_screens.dart';
import 'screens/survey_screens.dart';

class VotingApp extends StatelessWidget {
  const VotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AppRepository>();
    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: repository,
      redirect: (context, state) {
        final authenticated = repository.isAuthenticated;
        final isAuthPage =
            state.matchedLocation == '/' || state.matchedLocation == '/login';
        if (!authenticated && !isAuthPage) return '/';
        if (authenticated && isAuthPage) return '/home';
        if (state.matchedLocation == '/admin' && !repository.isAdmin) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: _page(const WelcomeScreen())),
        GoRoute(path: '/login', builder: _page(const LoginScreen())),
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/home', builder: _page(const DashboardScreen())),
            GoRoute(
              path: '/election/:id',
              builder: (_, state) =>
                  ElectionScreen(electionId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/confirm/:id',
              builder: (_, state) =>
                  ConfirmVoteScreen(electionId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/vote-submitted/:id',
              builder: (_, state) =>
                  VoteSubmittedScreen(electionId: state.pathParameters['id']!),
            ),
            GoRoute(path: '/my-votes', builder: _page(const MyVotesScreen())),
            GoRoute(
              path: '/survey/:id',
              builder: (_, state) =>
                  SurveyScreen(surveyId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/survey-submitted/:id',
              builder: (_, state) =>
                  SurveySubmittedScreen(surveyId: state.pathParameters['id']!),
            ),
            GoRoute(path: '/results', builder: _page(const ResultsScreen())),
            GoRoute(
              path: '/notifications',
              builder: _page(const NotificationsScreen()),
            ),
            GoRoute(path: '/profile', builder: _page(const ProfileScreen())),
            GoRoute(path: '/admin', builder: _page(const AdminScreen())),
            GoRoute(path: '/history', builder: _page(const HistoryScreen())),
            GoRoute(path: '/help', builder: _page(const HelpScreen())),
            GoRoute(path: '/help/faqs', builder: _page(const FaqScreen())),
            GoRoute(
              path: '/help/guidelines',
              builder: _page(const GuidelinesScreen()),
            ),
            GoRoute(
              path: '/help/contact',
              builder: _page(const ContactSupportScreen()),
            ),
            GoRoute(path: '/help/chat', builder: _page(const ChatScreen())),
            GoRoute(
              path: '/help/how-to-vote',
              builder: _page(const HowToVoteScreen()),
            ),
            GoRoute(
              path: '/help/report',
              builder: _page(const ReportProblemScreen()),
            ),
            GoRoute(
              path: '/help/report-submitted',
              builder: _page(const ReportSubmittedScreen()),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'School Online Voting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

Widget Function(BuildContext, GoRouterState) _page(Widget screen) =>
    (_, _) => screen;
