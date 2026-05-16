import 'user.dart';

class SessionSnapshot {
  const SessionSnapshot({
    required this.user,
    this.message,
    this.shouldShowConnectionDialog = false,
    this.shouldAttemptSessionRestore = false,
  });

  final User? user;
  final String? message;
  final bool shouldShowConnectionDialog;
  final bool shouldAttemptSessionRestore;
}
