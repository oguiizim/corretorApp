import 'package:flutter/material.dart';

import '../data/models/session_snapshot.dart';
import '../data/services/api_client.dart';
import '../data/services/app_session_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/property_service.dart';
import '../data/services/session_store.dart';
import '../ui/screens/auth_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/splash_screen.dart';

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  late final SessionStore _sessionStore;
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final PropertyService _propertyService;
  late final AppSessionService _appSessionService;
  Future<SessionSnapshot>? _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _sessionStore = SessionStore();
    _apiClient = ApiClient(_sessionStore);
    _authService = AuthService(_apiClient);
    _propertyService = PropertyService(_apiClient);
    _appSessionService = AppSessionService(
      sessionStore: _sessionStore,
      authService: _authService,
    );
    _bootstrapFuture = _appSessionService.bootstrap();
  }

  void _reload() {
    setState(() {
      _bootstrapFuture = _appSessionService.bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionSnapshot>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return AuthScreen(
            authService: _authService,
            appSessionService: _appSessionService,
            onAuthenticated: _reload,
            initialErrorMessage: snapshot.error.toString(),
            showInitialConnectionDialog: true,
            shouldAttemptSessionRestore: _appSessionService.hasSavedSession,
          );
        }

        final data = snapshot.data!;
        if (data.user == null) {
          return AuthScreen(
            authService: _authService,
            appSessionService: _appSessionService,
            onAuthenticated: _reload,
            initialErrorMessage: data.message,
            showInitialConnectionDialog: data.shouldShowConnectionDialog,
            shouldAttemptSessionRestore: data.shouldAttemptSessionRestore,
          );
        }

        return HomeScreen(
          authService: _authService,
          propertyService: _propertyService,
          appSessionService: _appSessionService,
          initialUser: data.user!,
          onLogout: _reload,
        );
      },
    );
  }
}
