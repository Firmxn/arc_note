class AppConstants {
  static const String appName = 'ArcNote';
  static const String appVersion = '1.0.0';

  // Route names
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String noteDetailRoute = '/note/:id';

  // Storage keys
  static const String sessionIdKey = 'session_id';
  static const String userIdKey = 'user_id';

  // Database names
  static const String databaseName = 'arcnote.db';

  // Supabase tables
  static const String pagesTable = 'pages';
  static const String blocksTable = 'blocks';
  static const String usersTable = 'users';
}