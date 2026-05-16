import '../models/session_snapshot.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'session_store.dart';

class AppSessionService {
  const AppSessionService({
    required SessionStore sessionStore,
    required AuthService authService,
  }) : _sessionStore = sessionStore,
       _authService = authService;

  final SessionStore _sessionStore;
  final AuthService _authService;

  Future<SessionSnapshot> bootstrap() async {
    await _sessionStore.init();

    if (!hasSavedSession) {
      return const SessionSnapshot(user: null);
    }

    try {
      final user = await _authService.getCurrentUser();
      return SessionSnapshot(user: user);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _sessionStore.clearToken();
        return const SessionSnapshot(user: null);
      }

      return SessionSnapshot(
        user: null,
        message: error.readableMessage,
        shouldShowConnectionDialog: true,
        shouldAttemptSessionRestore: true,
      );
    }
  }

  bool get hasSavedSession {
    final token = _sessionStore.token;
    return token != null && token.isNotEmpty;
  }

  Future<User?> tryRestoreSavedSession() async {
    if (!hasSavedSession) {
      return null;
    }

    try {
      return await _authService.getCurrentUser();
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _sessionStore.clearToken();
      }
      return null;
    }
  }

  Future<void> logout() {
    return _sessionStore.clearToken();
  }
}
