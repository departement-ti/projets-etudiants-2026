import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tunixplore/screens/organiser/modify_event_screen.dart';

import 'package:tunixplore/screens/place/place_screen_detail.dart';
import 'package:tunixplore/screens/settings/settings_sub_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/discover/discover_screen.dart';
import '../../screens/discover/itinerary_detail_screen.dart';
import '../../screens/event/event_detail_screen.dart';
import '../../screens/registration/registration_detail_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/organiser/organiser_dashboard_screen.dart';
import '../../screens/organiser/create_event_screen.dart';
import '../../screens/organiser/organiser_event_detail_screen.dart';
import '../../screens/reviews/reviews_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/profile/profile_edit_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/chatbot/chatbot_screen.dart';
import '../../screens/wishlist/wishlist_screen.dart';
import '../../widgets/common/shell_scaffold.dart';
import '../../widgets/common/organiser_shell_scaffold.dart';
import '../../services/user_session.dart';

// ─────────────────────────────────────────────────────────────
// Navigator keys
// ─────────────────────────────────────────────────────────────

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _orgShellKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────
// Route guard helper
// ─────────────────────────────────────────────────────────────

/// Returns true for routes that are always accessible (no auth required).
bool _isPublicRoute(String path) => path == '/login' || path == '/signup';

/// Returns true for any route that belongs to the organiser shell / flow.
bool _isOrganiserRoute(String path) => path.startsWith('/organiser');

// ─────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/login',

  // Re-evaluates [redirect] whenever UserSession notifies (role changes).
  refreshListenable: UserSession.instance,

  // ── Global redirect ─────────────────────────────────────────
  //
  // Logic (in order):
  //  1. Public routes → always allowed.
  //  2. No Firebase session → force /login.
  //  3. Firebase session exists but role not yet loaded → wait (no redirect).
  //  4. Visitor trying to reach an organiser route → send to /home.
  //  5. Everything else → allow.
  redirect: (context, state) {
    final path = state.uri.path;

    // 1. /login and /signup are always open
    if (_isPublicRoute(path)) return null;

    // 2. No Firebase session at all → back to login
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return '/login';

    // 3. Firebase session exists but role hasn't been fetched yet
    //    (happens during the very first frame after a cold start).
    //    Return null to let the current navigation proceed; once
    //    loadRoleIfLoggedIn() completes it will call notifyListeners
    //    and this redirect will run again with the real role.
    final role = UserSession.instance.role;
    if (role == null) return null;

    // 4. Visitor accessing organiser routes → redirect to visitor home
    if (_isOrganiserRoute(path) && !UserSession.instance.isOrganiser) {
      return '/home';
    }

    // 5. All other cases are allowed
    return null;
  },

  routes: [
    // ── Auth ─────────────────────────────────────────────────
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),

    // ── Visitor shell (bottom nav) ────────────────────────────
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (c, s, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/search', builder: (c, s) => const SearchScreen()),
        GoRoute(
          path: '/notifications',
          builder: (c, s) => const NotificationsScreen(),
        ),
        GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
        GoRoute(path: '/discover', builder: (c, s) => const DiscoverScreen()),
        GoRoute(path: '/wishlist', builder: (c, s) => const WishlistScreen()),
      ],
    ),

    // ── Organiser shell (bottom nav) ──────────────────────────
    // The global redirect above ensures only organisers ever reach these.
    ShellRoute(
      navigatorKey: _orgShellKey,
      builder: (c, s, child) => OrganiserShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/organiser',
          builder: (c, s) => const OrganiserDashboardScreen(),
        ),
        GoRoute(
          path: '/organiser/notifications',
          builder: (c, s) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/organiser/discover',
          builder: (c, s) => const DiscoverScreen(),
        ),
        
      ],
    ),

    // ── Events & Places ───────────────────────────────────────
    GoRoute(
      path: '/event/:id',
      builder: (c, s) => EventDetailScreen(eventId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/place/:id',
      builder: (c, s) =>
          PlaceDetailScreen(placeId: s.pathParameters['id'] ?? 'p1'),
    ),
    GoRoute(
      path: '/itinerary/:id',
      builder: (c, s) =>
          ItineraryDetailScreen(itineraryId: s.pathParameters['id'] ?? 'it1'),
    ),

    // ── Checkout ──────────────────────────────────────────────
    GoRoute(
      path: '/checkout/:eventId',
      builder: (c, s) => CheckoutScreen(
        eventId: s.pathParameters['eventId'] ?? 'e1',
        participants:
            int.tryParse(s.uri.queryParameters['participants'] ?? '1') ?? 1,
      ),
    ),
    GoRoute(
      path: '/checkout/success',
      builder: (c, s) => CheckoutSuccessScreen(
        eventId: s.uri.queryParameters['eventId'] ?? 'e1',
      ),
    ),

    // ── Registration ──────────────────────────────────────────
    GoRoute(
      path: '/registration/:id',
      builder: (c, s) => RegistrationDetailScreen(
        registrationId: s.pathParameters['id'] ?? 'r1',
      ),
    ),

    // ── Organiser standalone ──────────────────────────────────
    GoRoute(
      path: '/organiser/create',
      builder: (c, s) => const CreateEventScreen(),
    ),
    GoRoute(
      name: 'event-edit',
      path: '/organiser/event-edit/:id',
      builder: (context, state) {
        final eventId = state.pathParameters['id']!;
        return ModifyEventScreenLoader(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/organiser/event/:id',
      builder: (c, s) =>
          OrganiserEventDetailScreen(eventId: s.pathParameters['id'] ?? 'e1'),
    ),

    // ── Profile ───────────────────────────────────────────────
    GoRoute(
      path: '/profile/edit',
      builder: (c, s) => const ProfileEditScreen(),
    ),

    // ── Reviews & Chatbot ─────────────────────────────────────
    GoRoute(path: '/reviews', builder: (c, s) => const ReviewsScreen()),
    GoRoute(path: '/chatbot', builder: (c, s) => const ChatbotScreen()),

    GoRoute(
      path: '/settings/support',
      name: 'support',
      builder: (context, state) => const SupportScreen(),
    ),
    // ── Settings ──────────────────────────────────────────────
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    GoRoute(
      path: '/settings/password',
      builder: (c, s) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/settings/help',
      builder: (c, s) => const HelpCenterScreen(),
    ),
    GoRoute(path: '/settings/terms', builder: (c, s) => const TermsScreen()),
    GoRoute(path: '/settings/rate', builder: (c, s) => const RateAppScreen()),
  ],
);
