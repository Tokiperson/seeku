import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import/presentation/import_page.dart';
import '../features/schedule/presentation/course_detail_page.dart';
import '../features/schedule/presentation/course_form_page.dart';
import '../features/schedule/presentation/schedule_home_page.dart';
import '../features/settings/presentation/settings_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ScheduleHomePage()),
      GoRoute(
        path: '/courses/new',
        builder: (context, state) => const CourseFormPage(),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) =>
            CourseDetailPage(courseId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/courses/:id/edit',
        builder: (context, state) =>
            CourseFormPage(courseId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/import', builder: (context, state) => const ImportPage()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
